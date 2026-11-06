import Foundation

enum MealSlot: String, CaseIterable, Codable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: Self { self }

    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "leaf"
        }
    }

    static var current: Self {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 17..<22: .dinner
        default: .snack
        }
    }
}

struct Portion: Identifiable, Codable, Equatable {
    var id = UUID()
    var product: OFFProduct
    var amount: Double
    var meal: MealSlot
    var date: Date
    var created = Date.now
}

enum Nutrient: String, CaseIterable, Identifiable {
    case energy, protein, fat, carbs, fiber, sugars, salt
    var id: Self { self }
    var label: String {
        switch self {
        case .energy: "Energy"
        case .protein: "Protein"
        case .fat: "Fat"
        case .carbs: "Carbs"
        case .fiber: "Fiber"
        case .sugars: "Sugars"
        case .salt: "Salt"
        }
    }
    var unit: String { self == .energy ? "kcal" : "g" }
    func amount(in product: OFFProduct) -> Double? {
        let value: Double? = switch self {
        case .energy: product.kcal
        case .protein: product.protein
        case .fat: product.fat
        case .carbs: product.carbs
        case .fiber: product.fiber
        case .sugars: product.sugars
        case .salt: product.salt
        }
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }
}

struct NutrientTotal {
    let value: Double
    let known: Int
    let count: Int
    var isPartial: Bool { known > 0 && known < count }

    init(_ nutrient: Nutrient, _ entries: [Portion]) {
        let values = entries.compactMap { portion in
            nutrient.amount(in: portion.product).map { $0 * portion.amount / 100 }
        }
        value = values.reduce(0, +)
        known = values.count
        count = entries.count
    }

    func formatted(digits: Int = 0) -> String {
        guard known > 0 else { return "—" }
        guard isPartial else { return Daybook.number(value, digits: digits) }
        let scale = pow(10, Double(digits))
        return "≥ " + Daybook.number(floor(value * scale) / scale, digits: digits)
    }
}

enum Daybook {
    static let locale = Locale(identifier: "en_US")
    static var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    static func number(_ value: Double, digits: Int = 1) -> String {
        value.formatted(.number.locale(locale).precision(.fractionLength(0...digits)))
    }

    static func label(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    static func week(containing date: Date) -> [Date] {
        let cal = calendar
        guard let monday = cal.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    static func entries(_ all: [Portion], on date: Date) -> [Portion] {
        all.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.created > $1.created }
    }

    static func upserting(_ portion: Portion, in entries: [Portion]) -> [Portion] {
        var updated = entries
        if let index = updated.firstIndex(where: { $0.id == portion.id }) {
            updated[index] = portion
        } else {
            updated.append(portion)
        }
        return updated
    }

    static func parseAmount(_ text: String) -> Double? {
        let decimal = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard decimal.allSatisfy({ $0.isNumber || $0 == "." }),
              let amount = Double(decimal), amount.isFinite, (0.1...10_000).contains(amount) else { return nil }
        // Measurement is recorded to the nearest tenth of the label’s reference unit.
        return (amount * 10).rounded() / 10
    }

    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                    appropriateFor: nil, create: true)
            .appendingPathComponent("portion-diary-v1.json")
    }

    static func load() throws -> [Portion] {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([Portion].self, from: Data(contentsOf: url))
    }

    static func save(_ entries: [Portion]) throws {
        try JSONEncoder().encode(entries).write(to: fileURL(), options: .atomic)
    }
}
