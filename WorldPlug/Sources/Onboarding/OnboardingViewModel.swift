import Observation
import Repository
import SwiftData

// MARK: - OnboardingViewModelType

@MainActor
protocol OnboardingViewModelType: AnyObject, Observable {
    var searchQuery: String { get set }
    var selectedCountry: Country? { get set }
    var filteredCountries: [Country] { get }
}

// MARK: - OnboardingViewModel

@Observable
@MainActor
final class OnboardingViewModel: OnboardingViewModelType {
    var searchQuery: String = ""
    var selectedCountry: Country?

    private(set) var allCountries: [Country] = []

    var filteredCountries: [Country] {
        guard !searchQuery.isEmpty else {
            return allCountries
        }

        return allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    init(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Country>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        self.allCountries = all.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    init(countries: [Country]) {
        self.allCountries = countries.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}

// MARK: - PreviewOnboardingViewModel

#if DEBUG
@Observable
@MainActor
final class PreviewOnboardingViewModel: OnboardingViewModelType {
    var searchQuery: String = ""
    var selectedCountry: Country?
    private var allCountries: [Country]

    var filteredCountries: [Country] {
        guard !searchQuery.isEmpty else {
            return allCountries
        }

        return allCountries.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    init(countries: [Country] = []) {
        self.allCountries = countries
    }
}
#endif
