import Foundation
import Observation
import SwiftData

// MARK: - CountriesListViewModelType

@MainActor
public protocol CountriesListViewModelType {
    var filteredCountries: [Country] { get }

    func search(query: String)
}

// MARK: - CountriesListViewModel

@Observable
@MainActor
public final class CountriesListViewModel: CountriesListViewModelType {
    @ObservationIgnored private var countries: [Country] = []
    @ObservationIgnored private var modelContext: ModelContext

    public var filteredCountries: [Country] = []

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    public func fetchData() {
        do {
            let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
            countries = try modelContext.fetch(descriptor)
            filteredCountries = countries
        } catch {
            print("Fetch failed")
        }
    }

    public func search(query: String) {
        guard !query.isEmpty else {
            filteredCountries = countries
            return
        }

        filteredCountries = countries.lazy.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
