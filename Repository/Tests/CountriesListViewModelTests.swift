import Foundation
import SwiftData
import Testing

@testable import Repository

// MARK: - CountriesListViewModel Tests

@Suite("CountriesListViewModel")
@MainActor
struct CountriesListViewModelTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let viewModel: CountriesListViewModel

    init() throws {
        container = try makeContainer()
        context = container.mainContext

        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let japan = Country(code: "JP", voltage: "100V", frequency: "50Hz", flagUnicode: "🇯🇵")
        let usa = Country(code: "US", voltage: "120V", frequency: "60Hz", flagUnicode: "🇺🇸")
        context.insert(italy)
        context.insert(japan)
        context.insert(usa)
        try context.save()

        viewModel = CountriesListViewModel(modelContext: context)
    }

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

    @Test("search with empty string restores the full list")
    func emptySearchRestoresList() {
        viewModel.search(query: "ZZZZNOTACOUNTRY")
        viewModel.search(query: "")
        #expect(viewModel.filteredCountries.count == 3)
    }

    @Test("search filters countries whose name contains the query (case-insensitive)")
    func searchFiltersCorrectly() {
        let italyName = Locale.current.localizedString(forRegionCode: "IT") ?? ""
        guard !italyName.isEmpty else { return }

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

    @Test("consecutive searches are independent — second search operates on the original list")
    func consecutiveSearchesAreIndependent() {
        viewModel.search(query: "ZZZZNOTACOUNTRY")
        #expect(viewModel.filteredCountries.isEmpty)

        viewModel.search(query: "")
        #expect(viewModel.filteredCountries.count == 3)
    }
}
