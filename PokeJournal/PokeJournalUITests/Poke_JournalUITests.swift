//
//  Poke_JournalUITests.swift
//  PokéJournalUITests
//

import XCTest

final class Poke_JournalUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Essential Tests

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()

        // App should launch and have a window
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")

        // App should show either VaultSetupView or main content
        // Wait briefly to let the UI settle
        sleep(1)

        // The app is running if we get here without crash
        XCTAssertTrue(app.state == .runningForeground, "App should be running in foreground")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
