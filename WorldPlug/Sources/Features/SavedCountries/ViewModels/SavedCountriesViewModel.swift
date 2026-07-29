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
    var isTripEditorPresented = false
    var isPremiumPaywallPresented = false
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

    var isPremium: Bool { premiumEntitlement.isPremium }
    var nextTrip: NextTrip? { travelPreferencesStore.preferences.nextTrip }
    var homeCountryCode: String { homeCountryViewModel.homeCountryCode }

    var savedCountries: [Country] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return travelPreferencesStore.preferences.savedCountryCodes.compactMap { countriesByCode[$0] }
    }

    var favoriteWidgetCountry: Country? {
        guard let code = travelPreferencesStore.preferences.favoriteWidgetCountryCode else {
            return nil
        }
        return countries.first(where: { $0.code == code })
    }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.savedCountries)
    }

    func presentTripEditor() {
        isTripEditorPresented = true
    }

    func saveNextTrip(_ trip: NextTrip) -> Bool {
        let isNewTrip = nextTrip == nil
        travelPreferencesStore.setNextTrip(trip)
        return isNewTrip
    }

    func deleteNextTrip() {
        travelPreferencesStore.setNextTrip(nil)
    }

    func selectFavoriteWidgetCountry(code: String?) {
        travelPreferencesStore.setFavoriteWidgetCountry(code: code)
    }
}
