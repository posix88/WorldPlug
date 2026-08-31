import Analytics
import Foundation
import Observation
import Repository
import SwiftData

// MARK: - CountriesListViewModelType

@MainActor
protocol CountriesListViewModelType: AnyObject, Observable {
    var filteredCountries: [Country] { get }
    var compatibilitySummaries: [String: CountryCompatibilitySummary] { get }
    var searchQuery: String { get set }
    var selectedFilter: CountryCompatibilityFilter { get set }
    var navigationPath: [Country] { get set }
    var homeCountry: Country? { get }
    var pendingHomeCountry: Country? { get }
    var isHomeCountryConfirmationPresented: Bool { get set }
    var isPendingHomeCountryRemoval: Bool { get }
    var displayedCountries: [Country] { get }
    var filterCounts: [CountryCompatibilityFilter: Int] { get }
    func rowModel(for country: Country) -> CountryBrowserRowModel
    func handleHomeCountryAction(for country: Country)
    func confirmHomeCountryAction()
    func toggleSavedCountry(code: String) -> Bool
    func search(query: String)
    func search(query: String, locale: Locale)
    func screenAppeared(locale: Locale)
    func localeChanged(_ locale: Locale)
    func homeCountryChanged()
    func filterSelected()
    func openDeepLinkedCountry(code: String) -> Bool
}

// MARK: - CountriesListViewModel

@Observable
@MainActor
final class CountriesListViewModel: CountriesListViewModelType {
    @ObservationIgnored private var countries: [Country] = []
    @ObservationIgnored private var modelContext: ModelContext
    @ObservationIgnored private let homeCountryViewModel: any HomeCountryViewModelType
    @ObservationIgnored private let analyticsTracker: any AnalyticsTracker
    @ObservationIgnored private let travelPreferencesStore: any TravelPreferencesStoring
    @ObservationIgnored private let premiumEntitlement: any PremiumEntitlementProviding

    var filteredCountries: [Country] = []
    private(set) var compatibilitySummaries: [String: CountryCompatibilitySummary] = [:]
    var searchQuery = ""
    var selectedFilter: CountryCompatibilityFilter = .all
    var navigationPath: [Country] = []
    private(set) var pendingHomeCountry: Country?
    var isHomeCountryConfirmationPresented = false {
        didSet {
            if !isHomeCountryConfirmationPresented {
                pendingHomeCountry = nil
            }
        }
    }

    init(
        modelContext: ModelContext,
        homeCountryViewModel: any HomeCountryViewModelType,
        travelPreferencesStore: any TravelPreferencesStoring,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.modelContext = modelContext
        self.homeCountryViewModel = homeCountryViewModel
        self.travelPreferencesStore = travelPreferencesStore
        self.premiumEntitlement = premiumEntitlement
        self.analyticsTracker = analyticsTracker
        fetchData()
    }

    var homeCountry: Country? { homeCountryViewModel.homeCountry }

    var isPendingHomeCountryRemoval: Bool {
        pendingHomeCountry?.code == homeCountryViewModel.homeCountryCode
    }

    var displayedCountries: [Country] {
        guard selectedFilter != .all, !homeCountryViewModel.homeCountryCode.isEmpty else {
            return filteredCountries
        }

        return filteredCountries.filter {
            compatibilitySummaries[$0.code]?.filter == selectedFilter
        }
    }

    var filterCounts: [CountryCompatibilityFilter: Int] {
        var counts = Dictionary(uniqueKeysWithValues: CountryCompatibilityFilter.allCases.map { ($0, 0) })
        counts[.all] = filteredCountries.count
        for filter in compatibilitySummaries.values.map(\.filter) {
            counts[filter, default: 0] += 1
        }
        return counts
    }

    func fetchData() {
        do {
            countries = try modelContext.fetch(FetchDescriptor<Country>())
            search(query: "", locale: .current)
        } catch {
            // `assertionFailure` is compiled out in release, so without this the entire
            // catalog silently going empty (every feature depends on it) would be invisible
            // in production — at least surface it in analytics so it's discoverable.
            assertionFailure("Unable to fetch countries: \(error.localizedDescription)")
            analyticsTracker.track(
                .catalogFetchFailed,
                parameters: ["error": .string(String(describing: error))]
            )
        }
    }

    func search(query: String) {
        search(query: query, locale: .current)
    }

    func search(query: String, locale: Locale) {
        searchQuery = query
        filteredCountries = countries
            .filter { query.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(query) }
            .sortedByLocalizedName(in: locale)
        refreshCompatibilitySummaries()
    }

    func screenAppeared(locale: Locale) {
        analyticsTracker.screen(.countries)
        search(query: searchQuery, locale: locale)
    }

    func localeChanged(_ locale: Locale) {
        search(query: searchQuery, locale: locale)
    }

    func homeCountryChanged() {
        if homeCountryViewModel.homeCountryCode.isEmpty {
            selectedFilter = .all
        }
        refreshCompatibilitySummaries()
    }

    func filterSelected() {
        analyticsTracker.track(.compatibilityFilterSelected)
    }

    func openDeepLinkedCountry(code: String) -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let country = countries.first(where: { $0.code.uppercased() == normalizedCode }) else {
            return false
        }

        selectedFilter = .all
        search(query: "")
        navigationPath = [country]
        return true
    }

    func rowModel(for country: Country) -> CountryBrowserRowModel {
        CountryBrowserRowModel(
            country: country,
            isHomeCountry: country.code == homeCountryViewModel.homeCountryCode,
            hasHomeCountry: !homeCountryViewModel.homeCountryCode.isEmpty,
            isSavedCountry: travelPreferencesStore.isSavedCountry(code: country.code),
            isPremium: premiumEntitlement.isPremium
        )
    }

    func handleHomeCountryAction(for country: Country) {
        guard !homeCountryViewModel.homeCountryCode.isEmpty else {
            homeCountryViewModel.setHome(code: country.code)
            return
        }

        pendingHomeCountry = country
        isHomeCountryConfirmationPresented = true
    }

    func confirmHomeCountryAction() {
        guard let pendingHomeCountry else {
            assertionFailure("Cannot confirm a home-country action without a pending country.")
            isHomeCountryConfirmationPresented = false
            return
        }

        if pendingHomeCountry.code == homeCountryViewModel.homeCountryCode {
            homeCountryViewModel.clearHome()
        } else {
            homeCountryViewModel.setHome(code: pendingHomeCountry.code)
        }
        isHomeCountryConfirmationPresented = false
    }

    func toggleSavedCountry(code: String) -> Bool {
        guard premiumEntitlement.isPremium else {
            return false
        }

        travelPreferencesStore.toggleSavedCountry(code: code)
        return true
    }

    private func refreshCompatibilitySummaries() {
        compatibilitySummaries = CountryCompatibilityCalculator(
            homeCountryViewModel: homeCountryViewModel
        )
        .summaries(for: filteredCountries)
    }
}

#if DEBUG

// MARK: - PreviewCountriesListViewModel

@Observable
@MainActor
final class PreviewCountriesListViewModel: CountriesListViewModelType {
    private var allCountries: [Country]
    var filteredCountries: [Country]
    private(set) var compatibilitySummaries: [String: CountryCompatibilitySummary] = [:]
    var searchQuery = ""
    var selectedFilter: CountryCompatibilityFilter = .all
    var navigationPath: [Country] = []
    var homeCountry: Country?
    var pendingHomeCountry: Country?
    var isHomeCountryConfirmationPresented = false {
        didSet {
            if !isHomeCountryConfirmationPresented {
                pendingHomeCountry = nil
            }
        }
    }

    init(countries: [Country] = []) {
        self.allCountries = countries
        self.filteredCountries = countries
    }

    func search(query: String) {
        search(query: query, locale: .current)
    }

    func search(query: String, locale: Locale) {
        searchQuery = query
        filteredCountries = allCountries
            .filter { query.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(query) }
            .sortedByLocalizedName(in: locale)
    }

    var displayedCountries: [Country] { filteredCountries }
    var filterCounts: [CountryCompatibilityFilter: Int] { [.all: filteredCountries.count] }
    var isPendingHomeCountryRemoval: Bool { pendingHomeCountry?.code == homeCountry?.code }

    func screenAppeared(locale: Locale) { search(query: searchQuery, locale: locale) }
    func localeChanged(_ locale: Locale) { search(query: searchQuery, locale: locale) }
    func homeCountryChanged() {}
    func filterSelected() {}
    func rowModel(for country: Country) -> CountryBrowserRowModel {
        CountryBrowserRowModel(
            country: country,
            isHomeCountry: country.code == homeCountry?.code,
            hasHomeCountry: homeCountry != nil,
            isSavedCountry: false,
            isPremium: true
        )
    }

    func handleHomeCountryAction(for country: Country) {
        guard homeCountry != nil else {
            homeCountry = country
            return
        }

        pendingHomeCountry = country
        isHomeCountryConfirmationPresented = true
    }

    func confirmHomeCountryAction() {
        homeCountry = isPendingHomeCountryRemoval ? nil : pendingHomeCountry
        isHomeCountryConfirmationPresented = false
    }

    func toggleSavedCountry(code: String) -> Bool { true }

    func openDeepLinkedCountry(code: String) -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let country = allCountries.first(where: { $0.code.uppercased() == normalizedCode }) else {
            return false
        }

        selectedFilter = .all
        search(query: "")
        navigationPath = [country]
        return true
    }
}
#endif
