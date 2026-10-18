import XCTest

final class DJ1HUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDeviceDashboardShowsReferenceContent() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["设备"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["已接入设备"].exists)
        XCTAssertTrue(app.staticTexts["服务状态"].exists)
        XCTAssertTrue(app.buttons["serverSettingsButton"].exists)
    }

    @MainActor
    func testTabNavigationShowsMessagesScreen() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["消息"].tap()
        XCTAssertTrue(app.staticTexts["请先登录 VoHive"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testServerConfigurationRejectsInvalidURL() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_RESET"] = "1"
        app.launch()
        app.buttons["serverSettingsButton"].tap()
        let field = app.textFields["serverURLField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("http://public.example.com")
        app.buttons["loginButton"].tap()
        XCTAssertTrue(app.staticTexts["服务器必须使用 HTTPS（本地调试地址除外）。"].exists)
    }
}
