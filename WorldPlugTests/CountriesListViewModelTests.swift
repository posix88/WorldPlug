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

@Suite("CountriesListViewModel")
@MainActor
struct CountriesListViewModelTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let viewModel: CountriesListViewModel

    init() throws {
        self.container = try ModelContainer(
            for: Country.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        self.context = container.mainContext
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let japan = Country(code: "JP", voltage: "100V", frequency: "50Hz", flagUnicode: "🇯🇵")
        let usa = Country(code: "US", voltage: "120V", frequency: "60Hz", flagUnicode: "🇺🇸")
        context.insert(italy)
        context.insert(japan)
        context.insert(usa)
        try context.save()
        self.viewModel = CountriesListViewModel(modelContext: context)
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
        let names = viewModel.filteredCountries.map(\.name)
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
            $0.name.lowercased().contains(italyName.lowercased())
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
}

// MARK: - HomeCountryViewModelTests

@Suite("HomeCountryViewModel")
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
        let vm = HomeCountryViewModel(store: store, modelContext: container.mainContext)
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
                name: "Type \($0)",
                shortInfo: "",
                info: "",
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
