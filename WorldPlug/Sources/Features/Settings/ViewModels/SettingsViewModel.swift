import Analytics
import Foundation
import Observation
import Repository

// MARK: - SettingsRoute

enum SettingsRoute: Hashable {
    case homeCountryPicker
    case favoriteWidgetPicker
}

// MARK: - SettingsViewModel

@Observable
@MainActor
final class SettingsViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let travelPreferencesStore: any TravelPreferencesStoring
    private let homeCountryViewModel: any HomeCountryViewModelType
    private let analyticsTracker: any AnalyticsTracker

    private(set) var countries: [Country] = []
    var navigationPath: [SettingsRoute] = []
    var isPremiumPaywallPresented = false
    var isRestoring = false
    var restoreFailureMessage: String?

    /// `restoreFailureMessage != nil` as a settable flag, so the alert binds with
    /// `$viewModel.isRestoreFailureAlertPresented` rather than a closure `Binding` assembled in
    /// the view's body. Dismissal clears the message, which is what makes the alert one-shot.
    var isRestoreFailureAlertPresented: Bool {
        get { restoreFailureMessage != nil }
        set {
            guard !newValue else {
                return
            }

            restoreFailureMessage = nil
        }
    }

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

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    // MARK: Home country

    var homeCountryCode: String { homeCountryViewModel.homeCountryCode }

    var homeCountry: Country? {
        countries.first(where: { $0.code == homeCountryViewModel.homeCountryCode })
    }

    func setHomeCountry(code: String) {
        homeCountryViewModel.setHome(code: code)
    }

    func clearHomeCountry() {
        homeCountryViewModel.clearHome()
    }

    /// A settable projection so the picker can bind with `$viewModel.selectedHomeCountryCode`
    /// instead of a `Binding(get:set:)` built in the view's body — a closure binding allocates on
    /// every pass and, being a closure, compares unequal every time. An empty code means "no home
    /// country", which is why the setter branches rather than forwarding blindly.
    var selectedHomeCountryCode: String {
        get { homeCountryViewModel.homeCountryCode }
        set {
            if newValue.isEmpty {
                clearHomeCountry()
            } else {
                setHomeCountry(code: newValue)
            }
        }
    }

    // MARK: Favorite widget country

    /// The widget can only show a country the user has starred, so the picker offers exactly the
    /// saved ones. With nothing saved there is nothing to choose, and the row is disabled.
    var savedCountries: [Country] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return travelPreferencesStore.savedCountryCodes.compactMap { countriesByCode[$0] }
    }

    var favoriteWidgetCountry: Country? {
        guard let code = travelPreferencesStore.favoriteWidgetCountryCode else {
            return nil
        }

        return countries.first(where: { $0.code == code })
    }

    var canChooseFavoriteWidgetCountry: Bool { !savedCountries.isEmpty }

    func selectFavoriteWidgetCountry(code: String?) {
        travelPreferencesStore.setFavoriteWidgetCountry(code: code)
    }

    /// Settable projection for the widget picker's binding. `""` is the picker's "no selection"
    /// sentinel and maps to `nil` on the way in.
    var selectedFavoriteWidgetCountryCode: String {
        get { favoriteWidgetCountry?.code ?? "" }
        set { selectFavoriteWidgetCountry(code: newValue.isEmpty ? nil : newValue) }
    }

    // MARK: Premium

    func presentPaywall() {
        isPremiumPaywallPresented = true
    }

    func restorePurchases() async {
        guard !isRestoring else {
            return
        }

        isRestoring = true
        restoreFailureMessage = nil
        analyticsTracker.track(.premiumRestoreStarted)

        do {
            try await premiumEntitlement.restorePurchases()
            analyticsTracker.track(.premiumRestoreCompleted)
        } catch {
            // Surface it: a silent no-op here looks identical to "you never bought it", which is
            // exactly the moment a paying user needs to be told something went wrong.
            restoreFailureMessage = error.localizedDescription
        }

        isRestoring = false
    }

    // MARK: Lifecycle

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.settings)
    }
}
