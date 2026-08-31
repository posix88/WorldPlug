import XCTest

/// Drives the App Store screenshot pipeline: `fastlane snapshot` runs this test on every
/// device/locale combination in `Snapfile`, writing raw PNGs into `Scripts/screenshots/raw/`
/// (via `output_directory`). `render-all.mjs` then composites captions on top — see
/// `Scripts/screenshots/README.md`. Accessibility identifiers used below (`tab.*`,
/// `countryRow.*`) live on `RootTabView`/`CountryBrowserRow` — keep them in sync if those change.
final class WorldPlugUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        let language = isItalianSnapshot ? "it" : "en"
        app.launchArguments += [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", isItalianSnapshot ? "it_IT" : "en_US",
            "-hasSeenOnboarding", "YES",
            "-home.country.code", "GB"
        ]

        // 01 — Countries tab.
        launchMainApp(app)
        snapshot("01_countries")

        // 03 — Country Detail: search for a visually distinctive destination (Japan) so it's
        // findable regardless of scroll position in the 200+-country list, then tap its row.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        searchField.typeText(isItalianSnapshot ? "Giappone" : "Japan")

        let japanRow = app.buttons["countryRow.JP"]
        XCTAssertTrue(japanRow.waitForExistence(timeout: 5))
        japanRow.tap()

        XCTAssertTrue(app.navigationBars.staticTexts[isItalianSnapshot ? "Giappone" : "Japan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["100V"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[isItalianSnapshot ? "Tipo A" : "Type A"].waitForExistence(timeout: 5))
        snapshot("03_countrydetail", waitForLoadingIndicator: true)

        // 02 — Trip Check tab.
        launchMainApp(app)
        let tripCheckTab = app.tabBars.buttons["tab.tripCheck"]
        XCTAssertTrue(tripCheckTab.waitForExistence(timeout: 5))
        tripCheckTab.tap()
        snapshot("02_tripcheck")

        // 05 — Saved Countries tab (Premium features shown, not purchased in this flow).
        launchMainApp(app)
        let savedTab = app.tabBars.buttons["tab.saved"]
        XCTAssertTrue(savedTab.waitForExistence(timeout: 5))
        savedTab.tap()
        snapshot("05_saved")
    }

    @MainActor
    private func launchMainApp(_ app: XCUIApplication) {
        if app.state != .notRunning {
            app.terminate()
        }
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["tab.countries"].waitForExistence(timeout: 15))
    }

    @MainActor
    private var isItalianSnapshot: Bool {
        Snapshot.deviceLanguage.localizedCaseInsensitiveContains("it")
    }
}
