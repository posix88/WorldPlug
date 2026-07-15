import Analytics
import XCTest

final class AnalyticsEventTests: XCTestCase {
    func testScreenNamesAreStable() {
        XCTAssertEqual(AnalyticsScreen.countryDetail.rawValue, "country_detail")
        XCTAssertEqual(AnalyticsScreen.premiumPaywall.rawValue, "premium_paywall")
    }

    func testEventNamesAreStable() {
        XCTAssertEqual(AnalyticsEvent.premiumPurchaseCompleted.rawValue, "premium_purchase_completed")
        XCTAssertEqual(AnalyticsEvent.nextTripCreated.rawValue, "next_trip_created")
    }

    func testTrackerCanBeReplacedWithASpy() {
        let tracker = AnalyticsTrackerSpy()

        tracker.screen(.countries)
        tracker.track(.nextTripCreated, parameters: ["has_name": .boolean(true)])

        XCTAssertEqual(tracker.screens, [.countries])
        XCTAssertEqual(tracker.events, [.nextTripCreated])
    }
}

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
