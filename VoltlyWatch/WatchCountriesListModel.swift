import Foundation
import Observation
import Repository

// MARK: - WatchCountriesListModel

@Observable
@MainActor
final class WatchCountriesListModel {
    var searchQuery = "" {
        didSet {
            rebuildFilteredCountries()
        }
    }

    private(set) var filteredCountries: [CountrySnapshot]
    private var countries: [CountrySnapshot]

    init(countries: [CountrySnapshot]) {
        self.countries = countries
        self.filteredCountries = countries
    }

    func replaceCountries(with countries: [CountrySnapshot]) {
        guard self.countries != countries else {
            return
        }

        self.countries = countries
        rebuildFilteredCountries()
    }

    private func rebuildFilteredCountries() {
        guard !searchQuery.isEmpty else {
            filteredCountries = countries
            return
        }

        filteredCountries = countries.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }
}
