import Foundation
import Observation
import Repository
import SwiftData

// MARK: - CountriesListViewModelType

@MainActor
protocol CountriesListViewModelType: AnyObject, Observable {
    var filteredCountries: [Country] { get }
    func search(query: String)
}

// MARK: - CountriesListViewModel

@Observable
@MainActor
final class CountriesListViewModel: CountriesListViewModelType {
    @ObservationIgnored private var countries: [Country] = []
    @ObservationIgnored private var modelContext: ModelContext

    var filteredCountries: [Country] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    func fetchData() {
        do {
            let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            countries = try modelContext.fetch(descriptor)
            filteredCountries = countries
        } catch {
            print("Fetch failed")
        }
    }

    func search(query: String) {
        guard !query.isEmpty else {
            filteredCountries = countries
            return
        }

        filteredCountries = countries.lazy.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}

#if DEBUG

// MARK: - PreviewCountriesListViewModel

@Observable
@MainActor
final class PreviewCountriesListViewModel: CountriesListViewModelType {
    private var allCountries: [Country]
    var filteredCountries: [Country]

    init(countries: [Country] = []) {
        self.allCountries = countries
        self.filteredCountries = countries
    }

    func search(query: String) {
        guard !query.isEmpty else {
            filteredCountries = allCountries
            return
        }

        filteredCountries = allCountries.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
#endif
