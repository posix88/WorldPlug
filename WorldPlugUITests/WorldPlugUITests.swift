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

        XCTAssertTrue(app.tabBars.buttons["tab.countries"].waitForExistence(timeout: 15))
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

    func testTripCheck() {
        let app = XCUIApplication()
        let tripCheckTab = app.tabBars.buttons["tab.tripCheck"]
        XCTAssertTrue(tripCheckTab.waitForExistence(timeout: 5))
        tripCheckTab.tap()
        XCTAssertTrue(app.descendants(matching: .any)["tripCheck.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tripCheck.row.JP"].waitForExistence(timeout: 5))
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
