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
    var canSaveMoreCountries: Bool { get }
    func search(query: String)
    func search(query: String, locale: Locale)
    func screenAppeared(locale: Locale)
    func reloadCatalog(locale: Locale)
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

    /// `private(set)` because `displayedCountries` is now derived from it and kept in sync by
    /// `refreshCompatibilitySummaries()` — an outside write would leave the two disagreeing.
    private(set) var filteredCountries: [Country] = []
    private(set) var compatibilitySummaries: [String: CountryCompatibilitySummary] = [:]
    var searchQuery = ""
    var selectedFilter: CountryCompatibilityFilter = .all {
        didSet {
            guard oldValue != selectedFilter else {
                return
            }

            refreshDisplayedCountries()
        }
    }

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
    }

    var homeCountry: Country? { homeCountryViewModel.homeCountry }

    var isPendingHomeCountryRemoval: Bool {
        pendingHomeCountry?.code == homeCountryViewModel.homeCountryCode
    }

    /// The rows the list actually renders: `filteredCountries` narrowed by `selectedFilter`.
    ///
    /// Stored, not computed. It feeds a `ForEach`, and the collection handed to a `ForEach` is
    /// re-evaluated on every body pass of the enclosing view — so as a computed property this
    /// re-filtered all ~215 countries (with a dictionary lookup each) on invalidations that had
    /// nothing to do with the list: a sheet presenting, a toolbar button's state changing, an
    /// unrelated environment write. Recomputed only when one of its three inputs moves —
    /// `filteredCountries`, `compatibilitySummaries`, `selectedFilter`.
    private(set) var displayedCountries: [Country] = []

    private func refreshDisplayedCountries() {
        guard selectedFilter != .all, !homeCountryViewModel.homeCountryCode.isEmpty else {
            displayedCountries = filteredCountries
            return
        }

        displayedCountries = filteredCountries.filter {
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

    /// Reads the catalog once per view-model lifetime.
    ///
    /// Deliberately *not* called from `init`. A view's `init` runs every time its parent's body
    /// does, and `RootTabView` rebuilds all three `Tab` contents on every tab switch (and on
    /// every write to the four environment values it reads) — so a fetch in `init` meant a full
    /// 200-country SwiftData read, a localized sort and a compatibility pass, all thrown away by
    /// `@State`, on every tab tap.
    ///
    /// Retrying while `countries` is empty is intentional: the catalog is read-only and reseeded
    /// from bundled JSON, so "empty" only ever means "not loaded yet" or "the last fetch failed",
    /// and both want another attempt on the next appearance.
    func loadCatalogIfNeeded() {
        guard countries.isEmpty else {
            return
        }

        do {
            countries = try modelContext.fetch(FetchDescriptor<Country>())
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
        loadCatalogIfNeeded()
        search(query: searchQuery, locale: locale)
    }

    func reloadCatalog(locale: Locale) {
        do {
            countries = try modelContext.fetch(FetchDescriptor<Country>())
            search(query: searchQuery, locale: locale)
        } catch {
            assertionFailure("Unable to reload countries: \(error.localizedDescription)")
        }
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
            isSavedCountry: travelPreferencesStore.isSavedCountry(code: country.code)
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

    /// Whether the saved-country limit still has room, for the list's lock badge. Read from the
    /// list's own body (not from the lazily-built row model) so filling the last slot re-renders
    /// every row, not just the one that was tapped.
    var canSaveMoreCountries: Bool {
        premiumEntitlement.isPremium
            || travelPreferencesStore.savedCountryCodes.count < SavedCountryLimit.free
    }

    /// Returns `false` when the caller should show the paywall instead. A free user gets
    /// `SavedCountryLimit.free` saves before that happens, rather than the star being inert from
    /// the first tap.
    func toggleSavedCountry(code: String) -> Bool {
        guard SavedCountryLimit.allowsToggling(
            code: code,
            savedCountryCodes: travelPreferencesStore.savedCountryCodes,
            isPremium: premiumEntitlement.isPremium
        ) else {
            analyticsTracker.track(.savedCountryLimitReached)
            return false
        }

        travelPreferencesStore.toggleSavedCountry(code: code)
        return true
    }

    /// The single funnel for the two derived collections. Every path that changes
    /// `filteredCountries` or the home country ends here, so `displayedCountries` is refreshed
    /// exactly once per input change and never during a body pass.
    private func refreshCompatibilitySummaries() {
        compatibilitySummaries = CountryCompatibilityCalculator(
            homeCountryViewModel: homeCountryViewModel
        )
        .summaries(for: filteredCountries)

        refreshDisplayedCountries()
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
    func reloadCatalog(locale: Locale) { search(query: searchQuery, locale: locale) }
    func localeChanged(_ locale: Locale) { search(query: searchQuery, locale: locale) }
    func homeCountryChanged() {}
    func filterSelected() {}
    func rowModel(for country: Country) -> CountryBrowserRowModel {
        CountryBrowserRowModel(
            country: country,
            isHomeCountry: country.code == homeCountry?.code,
            hasHomeCountry: homeCountry != nil,
            isSavedCountry: false
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
    var canSaveMoreCountries: Bool { true }

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
