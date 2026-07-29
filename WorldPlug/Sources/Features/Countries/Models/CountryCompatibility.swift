import Repository
import SwiftUI

// MARK: - CountryCompatibilitySummary

enum CountryCompatibilitySummary: Equatable {
    case compatible
    case adapterNeeded
    case converterRequired

    var filter: CountryCompatibilityFilter {
        switch self {
        case .compatible: .compatible
        case .adapterNeeded: .adapterNeeded
        case .converterRequired: .converterRequired
        }
    }

    var title: String { filter.title }
    var icon: SFSymbols { filter.icon }
    var color: Color { filter.color }
}

@MainActor
struct CountryCompatibilityCalculator {
    let homeCountryViewModel: any HomeCountryViewModelType

    func summaries(for countries: [Country]) -> [String: CountryCompatibilitySummary] {
        guard !homeCountryViewModel.homeCountryCode.isEmpty else {
            return [:]
        }

        return Dictionary(
            uniqueKeysWithValues: countries.map { country in
                (country.code, summary(for: country))
            }
        )
    }

    private func summary(for country: Country) -> CountryCompatibilitySummary {
        guard country.code != homeCountryViewModel.homeCountryCode else {
            return .compatible
        }

        let compatibilities = country.sortedPlugs.map {
            homeCountryViewModel.plugCompatibility(for: $0, in: country)
        }

        if compatibilities.contains(.converterRequired) {
            return .converterRequired
        }
        if compatibilities.contains(.adapterNeeded) {
            return .adapterNeeded
        }
        return .compatible
    }
}
