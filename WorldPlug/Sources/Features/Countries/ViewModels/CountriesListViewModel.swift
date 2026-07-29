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
    var displayedCountries: [Country] { get }
    var filterCounts: [CountryCompatibilityFilter: Int] { get }
    func rowModel(for country: Country) -> CountryBrowserRowModel
    func toggleHomeCountry(code: String)
    func toggleSavedCountry(code: String) -> Bool
    func search(query: String)
    func search(query: String, locale: Locale)
    func screenAppeared(locale: Locale)
    func localeChanged(_ locale: Locale)
    func homeCountryChanged()
    func filterSelected()
    func openDeepLinkedCountry(code: String) -> Bool
    func clearHomeCountry()
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
            assertionFailure("Unable to fetch countries: \(error.localizedDescription)")
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

    func clearHomeCountry() {
        homeCountryViewModel.clearHome()
    }

    func rowModel(for country: Country) -> CountryBrowserRowModel {
        CountryBrowserRowModel(
            country: country,
            isHomeCountry: country.code == homeCountryViewModel.homeCountryCode,
            isSavedCountry: travelPreferencesStore.isSavedCountry(code: country.code),
            isPremium: premiumEntitlement.isPremium
        )
    }

    func toggleHomeCountry(code: String) {
        if code == homeCountryViewModel.homeCountryCode {
            homeCountryViewModel.clearHome()
        } else {
            homeCountryViewModel.setHome(code: code)
        }
    }

    func toggleSavedCountry(code: String) -> Bool {
        guard premiumEntitlement.isPremium else { return false }
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

    func screenAppeared(locale: Locale) { search(query: searchQuery, locale: locale) }
    func localeChanged(_ locale: Locale) { search(query: searchQuery, locale: locale) }
    func homeCountryChanged() {}
    func filterSelected() {}
    func clearHomeCountry() {}
    func rowModel(for country: Country) -> CountryBrowserRowModel {
        CountryBrowserRowModel(
            country: country,
            isHomeCountry: false,
            isSavedCountry: false,
            isPremium: true
        )
    }
    func toggleHomeCountry(code: String) {}
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
