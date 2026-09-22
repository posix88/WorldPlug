import Analytics
import Observation
import Repository

// MARK: - SavedCountriesViewModel

@Observable
@MainActor
final class SavedCountriesViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let travelPreferencesStore: any TravelPreferencesStoring
    private let homeCountryViewModel: any HomeCountryViewModelType
    private let analyticsTracker: any AnalyticsTracker

    private(set) var countries: [Country] = []
    var selectedCountry: Country?

    init(
        premiumEntitlement: any PremiumEntitlementProviding,
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.premiumEntitlement = premiumEntitlement
        self.travelPreferencesStore = travelPreferencesStore
        self.homeCountryViewModel = homeCountryViewModel
        self.analyticsTracker = analyticsTracker
    }

    var homeCountryCode: String { homeCountryViewModel.homeCountryCode }

    var savedCountries: [Country] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return travelPreferencesStore.savedCountryCodes.compactMap { countriesByCode[$0] }
    }

    /// "2 of 3 saved", so a free user discovers the ceiling here rather than being surprised by a
    /// paywall on their fourth star. `nil` for premium, which has no ceiling to report.
    var freeLimitHint: String? {
        let savedCountryCodes = travelPreferencesStore.savedCountryCodes
        guard SavedCountryLimit.remaining(
            savedCountryCodes: savedCountryCodes,
            isPremium: premiumEntitlement.isPremium
        ) != nil else {
            return nil
        }

        // The localized resource uses `%d` placeholders, so these must remain integer arguments.
        // Passing pre-formatted `String`s makes `String(format:)` interpret their memory addresses
        // as integers, which produces an implausibly large count in the UI.
        return LocalizationKeys.savedCountriesFreeLimit.string(
            savedCountryCodes.count,
            SavedCountryLimit.free
        )
    }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.savedCountries)
    }

    func removeSavedCountry(code: String) {
        guard travelPreferencesStore.isSavedCountry(code: code) else {
            return
        }

        travelPreferencesStore.toggleSavedCountry(code: code)
        if selectedCountry?.code == code {
            selectedCountry = nil
        }
    }
}
