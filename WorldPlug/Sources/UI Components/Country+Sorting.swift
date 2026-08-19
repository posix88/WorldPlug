import Foundation
import Repository

// MARK: - Country Sorting

extension Sequence<Country> {
    func sortedByLocalizedName(in locale: Locale) -> [Country] {
        sorted {
            $0.localizedName(in: locale)
                .localizedStandardCompare($1.localizedName(in: locale)) == .orderedAscending
        }
    }
}
