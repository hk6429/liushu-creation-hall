import XCTest

final class LiushuCreationHallSmokeTests: XCTestCase {
    func testImportedWebContentIsReachable() {
        var app = launchApp()

        XCTAssertTrue(app.navigationBars["六書造字堂"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["七日入堂"].waitForExistence(timeout: 3))

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

        app = launchApp(at: "stats")
        XCTAssertTrue(app.navigationBars["學習紀錄"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["各模式正確率"].exists)
    }

    func testPhaseTwoFeaturesAreReachable() {
        var app = launchFeature("journey")
        XCTAssertTrue(app.navigationBars["八卷旅程"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["進行今日五題"].exists)

        app = launchFeature("flash")
        XCTAssertTrue(app.navigationBars["閃卡複習"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["開始複習"].exists)

        app = launchFeature("daily")
        XCTAssertTrue(app.navigationBars["每日字陣"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["第 1／12 題"].waitForExistence(timeout: 3))

        app = launchFeature("battle")
        XCTAssertTrue(app.navigationBars["翰墨對決"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["挑戰"].firstMatch.exists)

        app = launchFeature("classroom")
        XCTAssertTrue(app.navigationBars["課堂共學"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["classroom-prompt-ben-xiu"].waitForExistence(timeout: 3))

        app = launchFeature("parent")
        XCTAssertTrue(app.navigationBars["家長陪學"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["開始 10 分鐘陪學"].exists)
    }

    func testOneSealEntryIsReachable() {
        let app = launchFeature("seal")
        XCTAssertTrue(app.navigationBars["今日一印"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["第 1 印・定錨"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["放學後"].exists)
        app.buttons["放學後"].tap()
        XCTAssertTrue(app.buttons["象形"].waitForExistence(timeout: 2))
        app.buttons["象形"].tap()
        let answer = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "正確答案：")).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["下一字"].exists)
        XCTAssertTrue(app.buttons["一字開卷完成，今天先收筆"].exists)
    }

    private func launchApp(at tab: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-test-reset"]
        if let tab {
            app.launchArguments += ["-ui-test-tab", tab]
        }
        app.launch()
        return app
    }

    private func launchFeature(_ feature: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-test-reset", "-ui-test-feature", feature]
        app.launch()
        return app
    }
}
