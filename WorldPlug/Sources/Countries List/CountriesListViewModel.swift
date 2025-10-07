import Foundation
import Repository
import SwiftData

// MARK: - CountriesListViewModelType

protocol CountriesListViewModelType {
    var filteredCountries: [Country] { get }

    func search(query: String)
}

// MARK: - CountriesListViewModel

@Observable
@MainActor
final class CountriesListViewModel {
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
