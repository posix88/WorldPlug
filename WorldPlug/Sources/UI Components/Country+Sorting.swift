import Foundation
import Repository

// MARK: - Country Sorting

extension Sequence where Element == Country {
    func sortedByLocalizedName(in locale: Locale) -> [Country] {
        sorted {
            $0.localizedName(in: locale)
                .localizedStandardCompare($1.localizedName(in: locale)) == .orderedAscending
        }
    }
}
