import CoreSpotlight
import Foundation
import Repository
import SwiftData

/// Keeps Voltly’s country catalog available to Spotlight and Apple Intelligence.
enum CountrySpotlightIndex {
    private static let name = "com.posix88.Voltly.countries"
    /// The catalog only changes between app versions (it's static, bundled JSON reseeded once
    /// per install), so there's no need to rebuild the entire Spotlight index on every cold
    /// launch — only when the app itself has been updated since the last successful index.
    private static let indexedVersionKey = "spotlight.indexed.catalog.version"

    static func index(_ entities: [CountryEntity]) async throws {
        try await CSSearchableIndex(name: name).indexAppEntities(entities)
    }

    @MainActor
    static func indexAllCountries() async throws {
        let currentVersion = catalogVersion
        guard UserDefaults.standard.string(forKey: indexedVersionKey) != currentVersion else {
            return
        }

        let countries = try Repository.sharedModelContainer.mainContext.fetch(FetchDescriptor<Country>())
        let entities = countries
            .sortedByLocalizedName(in: .current)
            .map { CountryEntity(country: $0) }

        try await index(entities)
        UserDefaults.standard.set(currentVersion, forKey: indexedVersionKey)
    }

    private static var catalogVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
