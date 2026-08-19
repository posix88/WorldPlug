import Observation
import Repository
import SwiftUI
import WidgetKit

// MARK: - AppCoordinator

@Observable
@MainActor
final class AppCoordinator {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    private let homeCountryViewModel: any HomeCountryViewModelType
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let navigationModel: AppNavigationModel
    private let appGroupDefaults: UserDefaults
    private let standardDefaults: UserDefaults
    /// Whether onboarding still needs to run, decided once at launch. Kept separate from
    /// `isOnboardingPresented` so the onboarding cover doesn't appear until the launch
    /// splash has finished — see `launchExperienceCompleted()`.
    private let needsOnboarding: Bool

    var premiumPaywallSource: PremiumPaywallSource?
    var isLaunchExperiencePresented = true
    /// Only ever flips to `true` from `launchExperienceCompleted()`, never at init, so a
    /// first-time user sees the launch splash before the onboarding cover appears on top of it.
    var isOnboardingPresented = false
    /// Flips to `true` once `premiumEntitlement.refreshEntitlements()` resolves. `LaunchExperienceView`
    /// waits for this (in addition to its minimum splash duration) before dismissing, so the app
    /// is never revealed with a stale/default `isPremium` — without this a genuinely premium user
    /// could briefly see locked content, or even have a tap during that window misrouted to the
    /// paywall, right after a cold launch.
    private(set) var hasRefreshedEntitlements = false

    init(
        homeCountryViewModel: any HomeCountryViewModelType,
        premiumEntitlement: any PremiumEntitlementProviding,
        navigationModel: AppNavigationModel,
        appGroupDefaults: UserDefaults,
        standardDefaults: UserDefaults
    ) {
        self.homeCountryViewModel = homeCountryViewModel
        self.premiumEntitlement = premiumEntitlement
        self.navigationModel = navigationModel
        self.appGroupDefaults = appGroupDefaults
        self.standardDefaults = standardDefaults
        self.needsOnboarding = !standardDefaults.bool(forKey: Keys.hasSeenOnboarding)
    }

    func start() async {
        syncPremiumWidgetAccess()
        await premiumEntitlement.refreshEntitlements()
        hasRefreshedEntitlements = true
        try? await CountrySpotlightIndex.indexAllCountries()
    }

    func sceneBecameActive() {
        homeCountryViewModel.refreshHomeCountry()
    }

    func premiumStatusChanged() {
        syncPremiumWidgetAccess()
    }

    func onboardingCompleted() {
        standardDefaults.set(true, forKey: Keys.hasSeenOnboarding)
        isOnboardingPresented = false
    }

    func launchExperienceCompleted() {
        isLaunchExperiencePresented = false
        if needsOnboarding {
            isOnboardingPresented = true
        }
    }

    func open(_ url: URL) {
        if VoltlyDeepLink.isPremiumURL(url) {
            premiumPaywallSource = .widget
        } else if let countryCode = VoltlyDeepLink.countryCode(from: url) {
            openCountry(code: countryCode)
        }
    }

    func openCountry(code: String) {
        navigationModel.openCountry(code: code)
    }

    private func syncPremiumWidgetAccess() {
        appGroupDefaults.set(premiumEntitlement.isPremium, forKey: AppGroup.premiumAccessKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
