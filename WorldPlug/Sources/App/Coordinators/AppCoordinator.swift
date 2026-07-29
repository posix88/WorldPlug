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
    private let appGroupDefaults: UserDefaults
    private let standardDefaults: UserDefaults

    var deepLinkedCountryCode: String?
    var premiumPaywallSource: PremiumPaywallSource?
    var isLaunchExperiencePresented = true
    var selectedTab = 0

    init(
        homeCountryViewModel: any HomeCountryViewModelType,
        premiumEntitlement: any PremiumEntitlementProviding,
        appGroupDefaults: UserDefaults,
        standardDefaults: UserDefaults
    ) {
        self.homeCountryViewModel = homeCountryViewModel
        self.premiumEntitlement = premiumEntitlement
        self.appGroupDefaults = appGroupDefaults
        self.standardDefaults = standardDefaults
    }

    var isOnboardingPresented: Bool {
        get { !standardDefaults.bool(forKey: Keys.hasSeenOnboarding) }
        set {
            if !newValue {
                standardDefaults.set(true, forKey: Keys.hasSeenOnboarding)
            }
        }
    }

    func start() async {
        syncPremiumWidgetAccess()
        openPendingCountryIfNeeded()
        await premiumEntitlement.refreshEntitlements()
        try? await CountrySpotlightIndex.indexAllCountries()
    }

    func sceneBecameActive() {
        homeCountryViewModel.refreshHomeCountry()
        openPendingCountryIfNeeded()
    }

    func premiumStatusChanged() {
        syncPremiumWidgetAccess()
    }

    func onboardingCompleted() {
        standardDefaults.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func launchExperienceCompleted() {
        isLaunchExperiencePresented = false
    }

    func open(_ url: URL) {
        guard url.scheme == "voltly" else { return }

        if url.host == "premium" {
            premiumPaywallSource = .widget
        } else if url.host == "country",
                  let countryCode = url.pathComponents.dropFirst().first {
            routeToCountry(code: countryCode)
        }
    }

    private func syncPremiumWidgetAccess() {
        appGroupDefaults.set(premiumEntitlement.isPremium, forKey: AppGroup.premiumAccessKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func openPendingCountryIfNeeded() {
        guard let countryCode = appGroupDefaults.string(forKey: AppGroup.pendingCountryCodeKey) else {
            return
        }
        appGroupDefaults.removeObject(forKey: AppGroup.pendingCountryCodeKey)
        routeToCountry(code: countryCode)
    }

    private func routeToCountry(code: String) {
        selectedTab = 0
        deepLinkedCountryCode = code.uppercased()
    }
}
