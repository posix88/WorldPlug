import Observation
import Repository
import SwiftData

// MARK: - OnboardingViewModel

@Observable
@MainActor
final class OnboardingViewModel {
    var searchQuery: String = ""
    var selectedCountry: Country?

    private(set) var allCountries: [Country] = []

    var filteredCountries: [Country] {
        guard !searchQuery.isEmpty else { return allCountries }
        return allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    init(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Country>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        allCountries = all.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
