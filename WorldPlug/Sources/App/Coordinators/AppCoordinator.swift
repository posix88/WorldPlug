import Observation
import Repository
import SwiftUI
import WidgetKit

// MARK: - AppPhase

enum AppPhase: Equatable {
    case launchExperience
    case onboarding
    case main
}

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
    private let usesDebugOverrides: Bool
    /// Whether onboarding still needs to run, decided once at launch.
    private let needsOnboarding: Bool

    var premiumPaywallSource: PremiumPaywallSource?
    private(set) var phase: AppPhase
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
        self.usesDebugOverrides = AppDebugOverrides.isEnabled
        self.needsOnboarding = !usesDebugOverrides
            && !standardDefaults.bool(forKey: Keys.hasSeenOnboarding)
        self.phase = usesDebugOverrides ? .main : .launchExperience
    }

    func start() async {
        // `isPremium` was hydrated from App Group storage before this coordinator was created.
        // Publish that stable, last-known value immediately, then let StoreKit reconcile it in
        // the background rather than holding the splash after its animation has ended.
        syncPremiumWidgetAccess()
        guard !usesDebugOverrides else {
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            await self.premiumEntitlement.refreshEntitlements()
            self.syncPremiumWidgetAccess()
            try? await CountrySpotlightIndex.indexAllCountries()
        }
    }

    func sceneBecameActive() {
        homeCountryViewModel.refreshHomeCountry()
    }

    func premiumStatusChanged() {
        syncPremiumWidgetAccess()
    }

    func onboardingCompleted() {
        standardDefaults.set(true, forKey: Keys.hasSeenOnboarding)
        phase = .main
    }

    func launchExperienceCompleted() {
        phase = needsOnboarding ? .onboarding : .main
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
