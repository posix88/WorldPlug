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

    var premiumPaywallSource: PremiumPaywallSource?
    var isLaunchExperiencePresented = true
    var isOnboardingPresented: Bool
    
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
        self.isOnboardingPresented = !standardDefaults.bool(forKey: Keys.hasSeenOnboarding)
    }

    func start() async {
        syncPremiumWidgetAccess()
        await premiumEntitlement.refreshEntitlements()
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
