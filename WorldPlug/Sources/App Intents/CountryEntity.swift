import AppIntents
import Repository
import SwiftData

/// A country that Voltly can resolve in Siri and the Shortcuts app.
struct CountryEntity: IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Country")
    static let defaultQuery = CountryEntityQuery()

    let id: String
    @Property(title: "Name") var name: String
    @Property(title: "Code") var code: String
    var flag: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(flag) \(name)",
            subtitle: "\(code)"
        )
    }

    @MainActor
    init(country: Country, locale: Locale = .current) {
        id = country.code
        flag = country.flagUnicode
        name = country.localizedName(in: locale)
        code = country.code
    }
}

struct CountryEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CountryEntity.ID]) async throws -> [CountryEntity] {
        let identifiers = Set(identifiers.map { $0.uppercased() })
        return await countryEntities { identifiers.contains($0.code) }
    }

    func entities(matching string: String) async throws -> [CountryEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return await countryEntities { country in
            country.code.localizedCaseInsensitiveContains(query) ||
            country.localizedName(in: .current).localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [CountryEntity] {
        await countryEntities { _ in true }
    }

    @MainActor
    private func countryEntities(
        matching predicate: (Country) -> Bool
    ) -> [CountryEntity] {
        let descriptor = FetchDescriptor<Country>()
        let countries = (try? Repository.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        return countries
            .filter(predicate)
            .sortedByLocalizedName(in: .current)
            .map { CountryEntity(country: $0) }
    }
}

/*
 iOS 27 adds automatic Spotlight reindexing through IndexedEntityQuery.
 When building with an iOS 27 SDK, add `import CoreSpotlight` above and uncomment:

 extension CountryEntityQuery: IndexedEntityQuery {
     func reindexEntities(
         for identifiers: [CountryEntity.ID],
         indexDescription: CSSearchableIndexDescription
     ) async throws {
         let identifiers = Set(identifiers.map { $0.uppercased() })
         let entities = await countryEntities { identifiers.contains($0.code) }
         try await CountrySpotlightIndex.index(entities)
     }

     func reindexAllEntities(
         indexDescription: CSSearchableIndexDescription
     ) async throws {
         try await CountrySpotlightIndex.indexAllCountries()
     }
 }
 */
