import XCTest

// Drives the App Store screenshot pipeline: `fastlane snapshot` runs this test on every
// device/locale combination in `Snapfile`, writing raw PNGs into `Scripts/screenshots/raw/`
// (via `output_directory`). `render-all.mjs` then composites captions on top — see
// `Scripts/screenshots/README.md`. Accessibility identifiers used below (`tab.*`,
// `countryRow.*`) live on `RootTabView`/`CountryBrowserRow` — keep them in sync if those change.
final class WorldPlugUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // 01 — Countries tab: the default launch screen.
        let countriesTab = app.tabBars.buttons["tab.countries"]
        if countriesTab.waitForExistence(timeout: 10) {
            countriesTab.tap()
        }
        snapshot("01_countries")

        // 03 — Country Detail: search for a visually distinctive destination (Japan) so it's
        // findable regardless of scroll position in the 200+-country list, then tap its row.
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
            searchField.typeText("Japan")

            let japanRow = app.buttons["countryRow.JP"]
            if japanRow.waitForExistence(timeout: 5) {
                japanRow.tap()
                snapshot("03_countrydetail")
                if app.navigationBars.buttons.element(boundBy: 0).exists {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                }
            }

            // Clear the search so later tabs don't reopen to a filtered list next launch.
            if let clearButton = searchField.buttons.allElementsBoundByIndex.first, clearButton.exists {
                clearButton.tap()
            }
        }

        // 02 — Trip Check tab.
        let tripCheckTab = app.tabBars.buttons["tab.tripCheck"]
        if tripCheckTab.waitForExistence(timeout: 5) {
            tripCheckTab.tap()
            snapshot("02_tripcheck")
        }

        // 05 — Saved Countries tab (Premium features shown, not purchased in this flow).
        let savedTab = app.tabBars.buttons["tab.saved"]
        if savedTab.waitForExistence(timeout: 5) {
            savedTab.tap()
            snapshot("05_saved")
        }
    }
}
