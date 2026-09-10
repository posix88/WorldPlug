import Foundation
import Observation
import Repository

// MARK: - CountryDestinationPickerViewModel

@Observable
@MainActor
final class CountryDestinationPickerViewModel {
    let countries: [Country]
    var searchQuery = ""

    init(countries: [Country]) {
        self.countries = countries
    }

    func filteredCountries(locale: Locale) -> [Country] {
        countries
            .filter {
                searchQuery.isEmpty ||
                    $0.localizedName(in: locale).localizedCaseInsensitiveContains(searchQuery)
            }
            .sortedByLocalizedName(in: locale)
    }
}
