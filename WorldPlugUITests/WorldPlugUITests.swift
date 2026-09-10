import XCTest

/// Drives the App Store screenshot pipeline: `fastlane snapshot` runs this test on every
/// device/locale combination in `Snapfile`, writing raw PNGs into `Scripts/screenshots/raw/`
/// (via `output_directory`). `render-all.mjs` then composites captions on top — see
/// `Scripts/screenshots/README.md`. Accessibility identifiers used below (`tab.*`,
/// `countryRow.*`) live on `RootTabView`/`CountryBrowserRow` — keep them in sync if those change.
@MainActor
final class WorldPlugUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        let language = isItalianSnapshot ? "it" : "en"
        app.launchArguments += [
            "UI_TEST_SEED_DATA",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", isItalianSnapshot ? "it_IT" : "en_US"
        ]
        if app.state != .notRunning {
            app.terminate()
        }
        app.launch()

        // Generous on purpose. `fastlane capture_raw_screenshots` runs with `reinstall_app: true`,
        // so every test here cold-launches the app, and the launch splash waits on
        // `premiumEntitlement.refreshEntitlements()` (with its own ~3s safety net) before it
        // dismisses. At 15s this assertion failed intermittently on a loaded machine — always in
        // setUp, before any test body ran — which took the whole screenshot lane down with it
        // (`stop_after_first_error`). 60s still fails fast if the app genuinely never launches.
        XCTAssertTrue(app.tabBars.buttons["tab.countries"].waitForExistence(timeout: 60))
    }

    func testCountries() {
        let app = XCUIApplication()
        XCTAssertTrue(app.descendants(matching: .any)["countries.list"].waitForExistence(timeout: 5))
        snapshot("01_countries")
    }

    func testCountryDetail() {
        let app = XCUIApplication()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        searchField.typeText(isItalianSnapshot ? "Giappone" : "Japan")

        let japanRow = app.buttons["countryRow.JP"]
        XCTAssertTrue(japanRow.waitForExistence(timeout: 5))
        japanRow.tap()

        XCTAssertTrue(app.navigationBars.staticTexts[isItalianSnapshot ? "Giappone" : "Japan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["countryDetail.infoSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["100V"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[isItalianSnapshot ? "Tipo A" : "Type A"].waitForExistence(timeout: 5))
        snapshot("03_countrydetail")
    }

    func testTrips() {
        let app = XCUIApplication()
        let tripsTab = app.tabBars.buttons["tab.trips"]
        XCTAssertTrue(tripsTab.waitForExistence(timeout: 5))
        tripsTab.tap()
        XCTAssertTrue(app.descendants(matching: .any)["trips.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["trips.row.JP"].waitForExistence(timeout: 5))
        snapshot("02_tripcheck")
    }

    func testSavedCountries() {
        let app = XCUIApplication()
        let savedTab = app.tabBars.buttons["tab.saved"]
        XCTAssertTrue(savedTab.waitForExistence(timeout: 5))
        savedTab.tap()
        XCTAssertTrue(app.descendants(matching: .any)["savedCountries.premiumContent"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedCountry.JP"].waitForExistence(timeout: 5))
        snapshot("05_saved")
    }

    private var isItalianSnapshot: Bool {
        Snapshot.deviceLanguage.localizedCaseInsensitiveContains("it")
    }
}
