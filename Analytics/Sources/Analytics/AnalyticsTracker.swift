import FirebaseAnalytics
import FirebaseCore
import Foundation

/// Application-facing analytics interface.
///
/// Depend on this protocol in features so analytics can be replaced by a spy in tests.
public protocol AnalyticsTracker: AnyObject {
    /// Records a screen view using a stable, app-owned screen name.
    func screen(_ screen: AnalyticsScreen)

    /// Records a product event with optional, typed parameters.
    func track(
        _ event: AnalyticsEvent,
        parameters: [String: AnalyticsValue]
    )
}

public extension AnalyticsTracker {
    func track(_ event: AnalyticsEvent) {
        track(event, parameters: [:])
    }
}

/// Firebase-backed implementation of ``AnalyticsTracker``.
public final class FirebaseAnalyticsTracker: AnalyticsTracker {
    public init() {}

    /// Configures Firebase once during app launch.
    public static func configure() {
        guard FirebaseApp.app() == nil else {
            return
        }

        FirebaseApp.configure()
    }

    /// Records a screen view using a stable, app-owned screen name.
    public func screen(_ screen: AnalyticsScreen) {
        FirebaseAnalytics.Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screen.rawValue,
                AnalyticsParameterScreenClass: screen.rawValue
            ]
        )
    }

    /// Records a product event with optional, typed parameters.
    public func track(
        _ event: AnalyticsEvent,
        parameters: [String: AnalyticsValue] = [:]
    ) {
        FirebaseAnalytics.Analytics.logEvent(
            event.rawValue,
            parameters: parameters.mapValues(\.firebaseValue)
        )
    }
}

/// No-op implementation for previews and features that do not collect analytics.
public final class NoopAnalyticsTracker: AnalyticsTracker {
    public init() {}

    public func screen(_ screen: AnalyticsScreen) {}

    public func track(
        _ event: AnalyticsEvent,
        parameters: [String: AnalyticsValue]
    ) {}
}

public enum AnalyticsScreen: String, Sendable {
    case countries 
    case countryDetail = "country_detail"
    case savedCountries = "saved_countries"
    case nextTrip = "next_trip"
    case onboarding
    case premiumPaywall = "premium_paywall"
}

public enum AnalyticsEvent: String, Sendable {
    case onboardingCompleted = "onboarding_completed"
    case homeCountrySet = "home_country_set"
    case homeCountryCleared = "home_country_cleared"
    case countrySaved = "country_saved"
    case countryUnsaved = "country_unsaved"
    case nextTripCreated = "next_trip_created"
    case nextTripUpdated = "next_trip_updated"
    case nextTripRemoved = "next_trip_removed"
    case premiumPaywallPresented = "premium_paywall_presented"
    case premiumPurchaseStarted = "premium_purchase_started"
    case premiumPurchaseCompleted = "premium_purchase_completed"
    case premiumRestoreStarted = "premium_restore_started"
    case premiumRestoreCompleted = "premium_restore_completed"
}

public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case integer(Int)
    case boolean(Bool)

    fileprivate var firebaseValue: Any {
        switch self {
        case .string(let value):
            value
        case .integer(let value):
            value
        case .boolean(let value):
            value
        }
    }
}
