import CoreSpotlight
import Foundation
import Repository
import SwiftData

/// Keeps Voltly’s country catalog available to Spotlight and Apple Intelligence.
enum CountrySpotlightIndex {
    private static let name = "com.posix88.Voltly.countries"
    /// Catalog data changes between app versions; localized names and descriptions also change
    /// when preferred app language changes. Stamp both so Spotlight never keeps stale-language data.
    private static let indexedCatalogKey = "spotlight.indexed.catalog.signature"

    static func index(_ entities: [CountryEntity]) async throws {
        try await CSSearchableIndex(name: name).indexAppEntities(entities)
    }

    @MainActor
    static func indexAllCountries(force: Bool = false) async throws {
        let locale = indexingLocale
        let currentSignature = catalogSignature(version: catalogVersion, locale: locale)
        let storedSignature = UserDefaults.standard.string(forKey: indexedCatalogKey)
        guard shouldIndex(storedSignature: storedSignature, currentSignature: currentSignature, force: force) else {
            return
        }

        let countries = try Repository.sharedModelContainer.mainContext.fetch(FetchDescriptor<Country>())
        let entities = countries
            .sortedByLocalizedName(in: locale)
            .map { CountryEntity(country: $0, locale: locale) }

        try await index(entities)
        UserDefaults.standard.set(currentSignature, forKey: indexedCatalogKey)
    }

    static func catalogSignature(version: String, locale: Locale) -> String {
        "\(version)|\(locale.identifier)"
    }

    static func shouldIndex(storedSignature: String?, currentSignature: String, force: Bool) -> Bool {
        force || storedSignature != currentSignature
    }

    private static var catalogVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var indexingLocale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
    }
}
