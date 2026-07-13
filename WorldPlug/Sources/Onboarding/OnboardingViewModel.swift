import Foundation
import Observation
import Repository
import SwiftData

// MARK: - OnboardingViewModelType

@MainActor
protocol OnboardingViewModelType: AnyObject, Observable {
    var searchQuery: String { get set }
    var selectedCountry: Country? { get set }
    func countries(for locale: Locale) -> [Country]
}

// MARK: - OnboardingViewModel

@Observable
@MainActor
final class OnboardingViewModel: OnboardingViewModelType {
    var searchQuery: String = ""
    var selectedCountry: Country?

    private(set) var allCountries: [Country] = []

    init(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Country>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        self.allCountries = all
    }

    init(countries: [Country]) {
        self.allCountries = countries
    }

    func countries(for locale: Locale) -> [Country] {
        allCountries
            .filter { searchQuery.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(searchQuery) }
            .sorted { $0.localizedName(in: locale).localizedStandardCompare($1.localizedName(in: locale)) == .orderedAscending }
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

    init(countries: [Country] = []) {
        self.allCountries = countries
    }

    func countries(for locale: Locale) -> [Country] {
        allCountries
            .filter { searchQuery.isEmpty || $0.localizedName(in: locale).localizedCaseInsensitiveContains(searchQuery) }
            .sorted { $0.localizedName(in: locale).localizedStandardCompare($1.localizedName(in: locale)) == .orderedAscending }
    }
}
#endif
