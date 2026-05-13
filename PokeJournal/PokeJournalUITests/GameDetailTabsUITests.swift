//
//  GameDetailTabsUITests.swift
//  PokéJournalUITests
//
//  Smoke tests that boot the app against the bundled test vault fixture
//  and visit each tab of GameDetailView. They verify the navigation path
//  end-to-end without making assertions about specific data.
//

import XCTest

@MainActor
final class GameDetailTabsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launchWithTestVault() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UseTestVault", "YES"]
        app.launch()
        return app
    }

    /// Waits for any game row from the fixture to appear, then clicks the first one.
    /// Returns the identifier of the game that was selected.
    @discardableResult
    private func selectAnyFixtureGame(_ app: XCUIApplication) -> String {
        // Fixture games (see TestVaultFixture.swift). All are RPG so they all appear in the sidebar.
        let candidates = [
            "gameRow_testrot",
            "gameRow_testsmaragd",
            "gameRow_testmond",
            "gameRow_testpurpur",
            "gameRow_testlegacy"
        ]
        // Wait up to 15s for the data loader to populate the sidebar.
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            for id in candidates {
                let row = app.descendants(matching: .any)[id]
                if row.exists {
                    row.click()
                    return id
                }
            }
            usleep(200_000)
        }
        XCTFail("No fixture game row appeared in the sidebar within 15s")
        return ""
    }

    // MARK: - Tests

    func testSidebar_populatedFromTestVault() throws {
        let app = launchWithTestVault()
        let id = selectAnyFixtureGame(app)
        XCTAssertFalse(id.isEmpty)
    }

    func testTabPicker_visibleAfterSelectingGame() throws {
        let app = launchWithTestVault()
        selectAnyFixtureGame(app)

        // The Picker has accessibilityIdentifier("tabPicker"). On macOS this maps to a
        // segmented control. Either query shape should locate it.
        let picker = app.descendants(matching: .any)["tabPicker"]
        XCTAssertTrue(
            picker.waitForExistence(timeout: 5),
            "Tab picker should be visible after a game is selected"
        )
    }

    func testEachTab_canBeActivated() throws {
        let app = launchWithTestVault()
        selectAnyFixtureGame(app)

        let picker = app.descendants(matching: .any)["tabPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))

        // Tab titles come from AppTab.title. If any of these change, this test
        // should fail with a clear message naming the missing tab.
        let titles = [
            "Sessions",
            "Timeline",
            "Heatmap",
            "Hall of Fame",
            "Team-Entwicklung",
            "Team-Check"
        ]

        for title in titles {
            let button = picker.buttons[title]
            XCTAssertTrue(
                button.waitForExistence(timeout: 3),
                "Expected tab segment '\(title)' to exist in the picker"
            )
            button.click()
            // Picker stays visible after switching; no crash means the tab's view rendered.
            XCTAssertTrue(picker.exists, "Tab picker disappeared after activating '\(title)'")
        }
    }
}
