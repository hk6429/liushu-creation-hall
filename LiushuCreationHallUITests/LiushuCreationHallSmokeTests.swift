import XCTest

final class LiushuCreationHallSmokeTests: XCTestCase {
    func testImportedWebContentIsReachable() {
        var app = launchApp()

        XCTAssertTrue(app.navigationBars["六書造字堂"].waitForExistence(timeout: 5))

        app = launchApp(at: "guide")
        XCTAssertTrue(app.navigationBars["六書導讀"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.segmentedControls.buttons["概念導讀"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["造字故事"].exists)

        app = launchApp(at: "catalog")
        XCTAssertTrue(app.navigationBars["字例總覽・220 字"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["找到 220 字"].waitForExistence(timeout: 3))

        let firstCharacter = app.buttons["人，ㄖㄣˊ，象形"]
        XCTAssertTrue(firstCharacter.waitForExistence(timeout: 3))
        firstCharacter.tap()
        XCTAssertTrue(app.navigationBars["人"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.images["人的字形與本義教學情境圖"].waitForExistence(timeout: 3))

        app = launchApp(at: "challenge")
        XCTAssertTrue(app.navigationBars["判字闖關"].waitForExistence(timeout: 3))
        for method in ["象形", "指事", "會意", "形聲", "轉注", "假借"] {
            XCTAssertTrue(app.buttons[method].waitForExistence(timeout: 3))
        }
    }

    private func launchApp(at tab: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        if let tab {
            app.launchArguments = ["-ui-test-tab", tab]
        }
        app.launch()
        return app
    }
}
