import CoreSpotlight
import Repository
import SwiftData

/// Keeps Voltly’s country catalog available to Spotlight and Apple Intelligence.
enum CountrySpotlightIndex {
    private static let name = "com.posix88.Voltly.countries"

    static func index(_ entities: [CountryEntity]) async throws {
        try await CSSearchableIndex(name: name).indexAppEntities(entities)
    }

    @MainActor
    static func indexAllCountries() async throws {
        let countries = try Repository.sharedModelContainer.mainContext.fetch(FetchDescriptor<Country>())
        let entities = countries
            .sortedByLocalizedName(in: .current)
            .map { CountryEntity(country: $0) }

        try await index(entities)
    }
}
