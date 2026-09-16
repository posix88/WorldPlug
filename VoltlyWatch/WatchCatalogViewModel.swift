import Foundation
import Observation
import Repository

// MARK: - WatchCatalogViewModel

@Observable
@MainActor
final class WatchCatalogViewModel {
    private(set) var countries: [CountrySnapshot] = []
    private(set) var loadError: String?
    private var loadedLocaleIdentifier: String?

    init(countries: [CountrySnapshot] = [], loadError: String? = nil) {
        self.countries = countries
        self.loadError = loadError
        loadedLocaleIdentifier = countries.isEmpty ? nil : Locale.current.identifier
    }

    func load(locale: Locale) {
        guard loadedLocaleIdentifier != locale.identifier else {
            return
        }

        do {
            countries = try CountrySnapshotRepository.allCountries(locale: locale)
            loadedLocaleIdentifier = locale.identifier
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func country(withCode code: String) -> CountrySnapshot? {
        guard !code.isEmpty else { return nil }
        return countries.first { $0.code == code }
    }
}
