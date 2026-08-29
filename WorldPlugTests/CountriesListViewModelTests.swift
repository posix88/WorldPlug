import Analytics
import Foundation
import Repository
import SwiftData
import Testing
@testable import WorldPlug

// MARK: - InMemoryHomeCountryStore

final class InMemoryHomeCountryStore: HomeCountryStoring {
    var homeCountryCode: String = ""
}

// MARK: - CountriesListViewModelTests

// `.serialized`: each test stands up its own in-memory SwiftData `ModelContainer`, and running
// them concurrently (Swift Testing's default) has been observed to intermittently fail with no
// code-level cause — consistent with in-memory `ModelConfiguration` containers created in a tight
// window colliding under the hood. Serializing trades a small amount of wall-clock time for
// reliable results.
@Suite("CountriesListViewModel", .serialized)
@MainActor
struct CountriesListViewModelTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let viewModel: CountriesListViewModel
    private let homeCountryViewModel: PreviewHomeCountryViewModel

    init() throws {
        self.container = try ModelContainer(
            for: Country.self, Plug.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        self.context = container.mainContext
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let japan = Country(code: "JP", voltage: "100V", frequency: "50Hz", flagUnicode: "🇯🇵")
        let usa = Country(code: "US", voltage: "120V", frequency: "60Hz", flagUnicode: "🇺🇸")
        // Every real country in the catalog has at least one plug type — give these fixtures one
        // too, otherwise `CountryCompatibilityCalculator.summary(for:)` has nothing to iterate
        // over and silently reports `.compatible` regardless of voltage.
        for (country, plugID) in [(italy, "F"), (japan, "A"), (usa, "B")] {
            let plug = Plug(
                id: plugID,
                images: [],
                specifications: .init(pinDiameter: "", pinSpacing: "", ratedAmperage: "", alsoKnownAs: "")
            )
            context.insert(plug)
            country.plugs = [plug]
        }
        context.insert(italy)
        context.insert(japan)
        context.insert(usa)
        try context.save()
        let homeCountryViewModel = PreviewHomeCountryViewModel(homeVoltage: "230V")
        self.homeCountryViewModel = homeCountryViewModel
        self.viewModel = CountriesListViewModel(
            modelContext: context,
            homeCountryViewModel: homeCountryViewModel,
            travelPreferencesStore: PreviewTravelPreferencesStore(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
    }

    // MARK: Fetch

    @Test("fetchData populates filteredCountries on init")
    func fetchDataOnInit() {
        #expect(viewModel.filteredCountries.isEmpty == false)
    }

    @Test("filteredCountries count matches inserted country count after init")
    func countMatchesInserted() {
        #expect(viewModel.filteredCountries.count == 3)
    }

    @Test("filteredCountries are sorted by name")
    func sortedByName() {
        let names = viewModel.filteredCountries.map { $0.localizedName(in: .current) }
        #expect(names == names.sorted())
    }

    // MARK: Search

    @Test("search with empty string restores the full list")
    func emptySearchRestoresList() {
        viewModel.search(query: "ZZZZNOTACOUNTRY")
        viewModel.search(query: "")
        #expect(viewModel.filteredCountries.count == 3)
    }

    @Test("search filters correctly (case-insensitive)")
    func searchFiltersCorrectly() {
        let italyName = Locale.current.localizedString(forRegionCode: "IT") ?? ""
        guard !italyName.isEmpty else {
            return
        }

        viewModel.search(query: italyName.lowercased())
        #expect(viewModel.filteredCountries.allSatisfy {
            $0.localizedName(in: .current).lowercased().contains(italyName.lowercased())
        })
    }

    @Test("search with a non-matching query returns an empty list")
    func noMatchReturnsEmpty() {
        viewModel.search(query: "ZZZZZZZZNOTACOUNTRY")
        #expect(viewModel.filteredCountries.isEmpty)
    }

    @Test("consecutive searches are independent")
    func consecutiveSearchesAreIndependent() {
        viewModel.search(query: "ZZZZNOTACOUNTRY")
        #expect(viewModel.filteredCountries.isEmpty)
        viewModel.search(query: "")
        #expect(viewModel.filteredCountries.count == 3)
    }

    @Test("compatibility summaries update from home-country state")
    func refreshCompatibilitySummaries() {
        homeCountryViewModel.setHome(code: "IT")
        viewModel.homeCountryChanged()

        #expect(viewModel.compatibilitySummaries["IT"] == .compatible)
        #expect(viewModel.compatibilitySummaries["JP"] == .converterRequired)
    }

    // MARK: Deep links

    @Test("deep link opens country hidden by search and resets browsing state")
    func deepLinkIgnoresActiveSearch() {
        viewModel.search(query: "ZZZZNOTACOUNTRY")
        viewModel.selectedFilter = .converterRequired

        let didOpen = viewModel.openDeepLinkedCountry(code: " it\n")

        #expect(didOpen)
        #expect(viewModel.navigationPath.map(\.code) == ["IT"])
        #expect(viewModel.searchQuery.isEmpty)
        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.filteredCountries.count == 3)
    }

    @Test("deep link rejects unknown country without changing navigation")
    func unknownDeepLinkIsIgnored() {
        let didOpen = viewModel.openDeepLinkedCountry(code: "XX")

        #expect(didOpen == false)
        #expect(viewModel.navigationPath.isEmpty)
    }
}

// MARK: - HomeCountryViewModelTests

/// See the `.serialized` note on `CountriesListViewModelTests` above — same reasoning applies here.
@Suite("HomeCountryViewModel", .serialized)
@MainActor
struct HomeCountryViewModelTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Country.self, Plug.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeVM(container: ModelContainer, homeCode: String = "") -> (HomeCountryViewModel, InMemoryHomeCountryStore) {
        let store = InMemoryHomeCountryStore()
        store.homeCountryCode = homeCode
        let travelPreferencesStore = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(homeCountryCode: homeCode)
        )
        let vm = HomeCountryViewModel(
            store: store,
            travelPreferencesStore: travelPreferencesStore,
            modelContext: container.mainContext
        )
        return (vm, store)
    }

    private func makeCountry(
        code: String,
        voltage: String = "230V",
        plugIDs: [String] = [],
        in context: ModelContext
    ) -> Country {
        let country = Country(code: code, voltage: voltage, frequency: "50Hz", flagUnicode: "🏳️")
        country.plugs = plugIDs.map {
            let plug = Plug(
                id: $0,
                images: [],
                specifications: .init(pinDiameter: "", pinSpacing: "", ratedAmperage: "", alsoKnownAs: "")
            )
            context.insert(plug)
            return plug
        }
        context.insert(country)
        return country
    }

    @Test("homeCountry is nil when code is empty")
    func homeCountryNilWhenEmpty() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container)
        #expect(vm.homeCountry == nil)
    }

    @Test("homeCountry returns matching country")
    func homeCountryMatchesCode() throws {
        let container = try makeContainer()
        _ = makeCountry(code: "IT", in: container.mainContext)
        try container.mainContext.save()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.homeCountry?.code == "IT")
    }

    @Test("homeCountry is nil for unknown code")
    func homeCountryNilForUnknownCode() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container, homeCode: "XX")
        #expect(vm.homeCountry == nil)
    }

    @Test("homePlugTypeIDs is empty when no home country")
    func homePlugTypeIDsEmptyWithoutHome() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container)
        #expect(vm.homePlugTypeIDs.isEmpty)
    }

    @Test("homePlugTypeIDs reflects home country plugs")
    func homePlugTypeIDsReflectsPlugs() throws {
        let container = try makeContainer()
        _ = makeCountry(code: "IT", plugIDs: ["C", "F", "L"], in: container.mainContext)
        try container.mainContext.save()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.homePlugTypeIDs == ["C", "F", "L"])
    }

    @Test("clearHome resets code to empty")
    func clearHomeResetsCode() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        vm.clearHome()
        #expect(vm.homeCountryCode.isEmpty)
    }

    @Test("setHome persists through the store")
    func setHomePersistsThroughStore() throws {
        let container = try makeContainer()
        let (vm, store) = makeVM(container: container)
        vm.setHome(code: "DE")
        #expect(store.homeCountryCode == "DE")
    }

    @Test("setHome normalizes country codes before persisting")
    func setHomeNormalizesCode() throws {
        let container = try makeContainer()
        let (vm, store) = makeVM(container: container)
        vm.setHome(code: " it\n")
        #expect(vm.homeCountryCode == "IT")
        #expect(store.homeCountryCode == "IT")
    }

    @Test("setHome resolves an unchanged code after the catalogue loads")
    func setHomeResolvesUnchangedCodeAfterCatalogueLoads() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.homeCountry == nil)
        _ = makeCountry(code: "IT", in: container.mainContext)
        try container.mainContext.save()

        vm.setHome(code: "IT")

        #expect(vm.homeCountry?.code == "IT")
    }

    @Test("refresh resolves an unchanged code after the catalogue loads")
    func refreshResolvesUnchangedCodeAfterCatalogueLoads() throws {
        let container = try makeContainer()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.homeCountry == nil)
        _ = makeCountry(code: "IT", in: container.mainContext)
        try container.mainContext.save()

        vm.refreshHomeCountry()

        #expect(vm.homeCountry?.code == "IT")
    }

    @Test("clearHome persists empty string through the store")
    func clearHomePersistsThroughStore() throws {
        let container = try makeContainer()
        let (vm, store) = makeVM(container: container, homeCode: "DE")
        vm.clearHome()
        #expect(store.homeCountryCode.isEmpty)
    }

    @Test("plugCompatibility returns adapterNeeded when voltage is compatible but plug differs")
    func plugCompatibilityAdapterNeeded() throws {
        let container = try makeContainer()
        _ = makeCountry(code: "IT", voltage: "230V", plugIDs: ["C"], in: container.mainContext)
        let destination = makeCountry(code: "GB", voltage: "240V", plugIDs: ["G"], in: container.mainContext)
        try container.mainContext.save()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.plugCompatibility(for: destination.plugs[0], in: destination) == .adapterNeeded)
    }

    @Test("plugCompatibility returns converterRequired when voltage differs")
    func plugCompatibilityConverterRequired() throws {
        let container = try makeContainer()
        _ = makeCountry(code: "IT", voltage: "230V", plugIDs: ["C"], in: container.mainContext)
        let destination = makeCountry(code: "US", voltage: "120V", plugIDs: ["C"], in: container.mainContext)
        try container.mainContext.save()
        let (vm, _) = makeVM(container: container, homeCode: "IT")
        #expect(vm.plugCompatibility(for: destination.plugs[0], in: destination) == .converterRequired)
    }
}
