import Foundation
import Observation
import Repository
import SwiftData

// MARK: - CountriesListViewModelType

@MainActor
protocol CountriesListViewModelType: AnyObject, Observable {
    var filteredCountries: [Country] { get }
    func search(query: String)
    func search(query: String, locale: Locale)
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
        filteredCountries = countries
            .filter { query.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(query) }
            .sortedByLocalizedName(in: locale)
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
        search(query: query, locale: .current)
    }

    func search(query: String, locale: Locale) {
        filteredCountries = allCountries
            .filter { query.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(query) }
            .sortedByLocalizedName(in: locale)
    }
}
#endif
