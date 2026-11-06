import XCTest
@testable import PortionNote

final class PortionNoteTests: XCTestCase {
    private func product(_ nutrients: [String: Double] = [:]) -> OFFProduct {
        OFFProduct(record: ["code": "12345678", "product_name": "Muesli", "brands": "Orchard Foods", "nutriments": nutrients])!
    }

    func testNutrientsScaleByWeightAndRetainMissingValues() {
        let known = Portion(product: product(["energy-kcal_100g": 370, "proteins_100g": 8]),
                            amount: 25, meal: .breakfast, date: .now)
        let unknown = Portion(product: product(), amount: 50, meal: .snack, date: .now)
        let partial = NutrientTotal(.energy, [known, unknown])
        XCTAssertEqual(partial.value, 92.5, accuracy: 0.0001)
        XCTAssertEqual(partial.formatted(), "≥ 92")
        XCTAssertEqual(partial.known, 1)
        XCTAssertEqual(partial.count, 2)
        XCTAssertTrue(partial.isPartial)
        XCTAssertEqual(NutrientTotal(.protein, [known]).formatted(digits: 1), "2")
        XCTAssertEqual(NutrientTotal(.fat, [known, unknown]).formatted(), "—")
        XCTAssertEqual(NutrientTotal(.energy, []).formatted(), "—")
    }

    func testConfirmedZeroIsNotUnknown() {
        let tea = Portion(product: product(["energy-kcal_100g": 0, "sugars_100g": 0]),
                          amount: 180, meal: .lunch, date: .now)
        XCTAssertEqual(NutrientTotal(.sugars, [tea]).formatted(digits: 1), "0")
        XCTAssertFalse(NutrientTotal(.energy, [tea]).isPartial)
    }

    func testInputBoundariesAndDecimalComma() {
        XCTAssertEqual(Daybook.parseAmount(" 12,45 "), 12.5)
        XCTAssertEqual(Daybook.parseAmount("0,1"), 0.1)
        XCTAssertEqual(Daybook.parseAmount("10000"), 10_000)
        for value in ["0", "-10", "10000.1", ".01", "3..2", "NaN", "inf", "1e4", ""] {
            XCTAssertNil(Daybook.parseAmount(value), value)
        }
    }

    func testCorrectionRemovalAndDayBoundaries() throws {
        let cal = Daybook.calendar
        let sunday = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 23)))
        let monday = try XCTUnwrap(cal.date(byAdding: .hour, value: 2, to: sunday))
        var portion = Portion(product: product(["energy-kcal_100g": 100]), amount: 90, meal: .dinner, date: sunday)
        var entries = Daybook.upserting(portion, in: [])
        let id = portion.id
        portion.date = monday; portion.amount = 150; portion.meal = .snack
        entries = Daybook.upserting(portion, in: entries)
        XCTAssertTrue(Daybook.entries(entries, on: sunday).isEmpty)
        XCTAssertEqual(Daybook.entries(entries, on: monday).map(\.id), [id])
        XCTAssertEqual(NutrientTotal(.energy, Daybook.entries(entries, on: monday)).value, 150)
        let week = Daybook.week(containing: monday)
        XCTAssertEqual(week.count, 7)
        XCTAssertTrue(cal.isDate(try XCTUnwrap(week.first), inSameDayAs: monday))
        entries.removeAll { $0.id == id }
        XCTAssertTrue(Daybook.entries(entries, on: monday).isEmpty)
    }

    func testSavedPortionRoundTrips() throws {
        let original = Portion(product: product(["energy-kcal_100g": 370]), amount: 37.5, meal: .snack, date: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode([original])
        let loaded = try JSONDecoder().decode([Portion].self, from: data)
        XCTAssertEqual(loaded, [original])
    }
}

final class CatalogParsingTests: XCTestCase {
    private func barcode(_ fields: [String: Any]) throws -> OFFProduct {
        var record: [String: Any] = ["code": "0123456789012", "product_name": "Oat drink"]
        record.merge(fields) { _, updated in updated }
        let data = try JSONSerialization.data(withJSONObject: ["status": 1, "product": record])
        return try XCTUnwrap(FoodCatalog.parse(data, barcode: true).first)
    }

    func testMissingNutritionZeroAndKilojoules() throws {
        let drink = try barcode(["nutriments": ["energy-kj_100g": "418.4", "sugars_100g": 0, "salt_100g": -2]])
        XCTAssertEqual(try XCTUnwrap(drink.kcal), 100, accuracy: 0.0001)
        XCTAssertEqual(drink.sugars, 0)
        XCTAssertNil(drink.protein)
        XCTAssertNil(drink.salt)
        let explicitZero = try barcode(["nutriments": ["energy-kcal_100g": 0, "energy_100g": 418.4]])
        XCTAssertEqual(explicitZero.kcal, 0)
        XCTAssertNil(try barcode([:]).kcal)
    }

    func testEnglishNamesAndIngredientsPreferEnglishLabels() throws {
        let translated = try barcode(["lang": "fr", "product_name": "Boisson", "product_name_en": "Oat drink",
                                      "ingredients_text": "Eau, avoine", "ingredients_text_en": " Water, oats "])
        XCTAssertEqual(translated.name, "Oat drink")
        XCTAssertEqual(translated.ingredients, "Water, oats")

        let unlabelled = try barcode(["lang": "fr", "product_name": "Boisson", "ingredients_text": "Eau, avoine"])
        XCTAssertEqual(unlabelled.name, "Boisson")
        XCTAssertNil(unlabelled.ingredients)
        XCTAssertEqual(try barcode(["lang": "en", "ingredients_text": "Water, oats"]).ingredients, "Water, oats")
    }

    func testExplicitNutritionBasisBeforePackageVolume() throws {
        XCTAssertEqual(try barcode(["nutrition_data_per": "100g", "product_quantity_unit": "ml"]).amountUnit, "g")
        XCTAssertEqual(try barcode(["nutrition_data_per": "100ml", "product_quantity_unit": "g"]).amountUnit, "ml")
        XCTAssertEqual(try barcode(["product_quantity_unit": "cl"]).amountUnit, "ml")
        XCTAssertEqual(try barcode(["quantity": "1.5 L"]).amountUnit, "ml")
        XCTAssertEqual(try barcode(["quantity": "500 g"]).amountUnit, "g")
    }

    func testSearchDeduplicatesByBarcodeAndPreservesLeadingZeroes() throws {
        let records = [
            ["code": "0123456789012", "product_name": "First label"],
            ["code": "not-a-code", "product_name": "Invalid"],
            ["code": "0123456789012", "product_name": "Duplicate"],
            ["code": "5012345678910", "product_name": "Another label"]
        ]
        let data = try JSONSerialization.data(withJSONObject: ["products": records])
        let products = try FoodCatalog.parse(data, barcode: false)
        XCTAssertEqual(products.map(\.id), ["0123456789012", "5012345678910"])
        XCTAssertEqual(products.map(\.name), ["First label", "Another label"])
    }
}
