import Analytics
import XCTest

// MARK: - AnalyticsEventTests

final class AnalyticsEventTests: XCTestCase {
    func testScreenNamesAreStable() {
        XCTAssertEqual(AnalyticsScreen.countryDetail.rawValue, "country_detail")
        XCTAssertEqual(AnalyticsScreen.premiumPaywall.rawValue, "premium_paywall")
    }

    func testEventNamesAreStable() {
        XCTAssertEqual(AnalyticsEvent.premiumPurchaseCompleted.rawValue, "premium_purchase_completed")
        XCTAssertEqual(AnalyticsEvent.compatibilityGuideOpened.rawValue, "compatibility_guide_opened")
    }

    func testTrackerCanBeReplacedWithASpy() {
        let tracker = AnalyticsTrackerSpy()

        tracker.screen(.countries)
        tracker.track(.homeCountryPickerOpened, parameters: ["source": .string("setup")])

        XCTAssertEqual(tracker.screens, [.countries])
        XCTAssertEqual(tracker.events, [.homeCountryPickerOpened])
    }
}

// MARK: - AnalyticsTrackerSpy

private final class AnalyticsTrackerSpy: AnalyticsTracker {
    private(set) var screens: [AnalyticsScreen] = []
    private(set) var events: [AnalyticsEvent] = []

    func screen(_ screen: AnalyticsScreen) {
        screens.append(screen)
    }

    func track(
        _ event: AnalyticsEvent,
        parameters: [String: AnalyticsValue]
    ) {
        events.append(event)
    }
}
