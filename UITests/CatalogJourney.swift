import XCTest

@MainActor
final class CatalogJourney: XCTestCase {
    func testProductFromCatalogToSavedRecord() {
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", ""]
        app.launch()
        let find = app.buttons["journal.add"]
        XCTAssertTrue(find.waitForExistence(timeout: 10))
        capture(app, "01-Empty-journal")
        find.tap()
        let product = app.buttons["catalog.product.5010029000016"]
        XCTAssertTrue(product.waitForExistence(timeout: 10))
        capture(app, "02-Food-catalog")
        product.tap()
        let save = app.buttons["journal.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        capture(app, "03-Portion-editor")
        save.tap()
        let result = app.staticTexts["kcal logged"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Saved product"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["journal.week"].tap()
        XCTAssertTrue(app.staticTexts["Your week\nin food"].waitForExistence(timeout: 5))
        capture(app, "05-Weekly-summary")
        app.buttons["journal.day"].tap()
        app.buttons["journal.calendar"].tap()
        XCTAssertTrue(app.navigationBars["Journal date"].waitForExistence(timeout: 5))
        capture(app, "06-Calendar")
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(result.waitForExistence(timeout: 10))
    }

    func testLargeTypeEntryControlsRemainUsable() {
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", "",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let add = app.buttons["journal.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        capture(app, "07-Large-type-journal")
        add.tap()
        XCTAssertTrue(app.navigationBars["Food catalog"].waitForExistence(timeout: 10))
        let product = app.buttons["catalog.product.5010029000016"]
        for _ in 0..<8 {
            if product.exists && product.isHittable { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(product.isHittable)
        capture(app, "08-Large-type-catalog")
        product.tap()
        let save = app.buttons["journal.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        let preset = app.buttons["150 g"]
        for _ in 0..<8 {
            if preset.exists && preset.isHittable && preset.frame.maxY < save.frame.minY - 8 {
                break
            }
            app.scrollViews["journal.editor.scroll"].swipeUp()
        }
        XCTAssertLessThan(preset.frame.maxY, save.frame.minY)
        preset.tap()
        XCTAssertEqual(app.textFields["journal.amount"].value as? String, "150")
        capture(app, "09-Large-type-editor")
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.staticTexts["kcal logged"].waitForExistence(timeout: 10))
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
