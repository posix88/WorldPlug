import Foundation
import os
import SwiftData

public typealias Plug = SchemaV5.Plug
public typealias Country = SchemaV5.Country

// MARK: - Repository

public enum Repository {
    /// `print` output is easy to miss outside a debugger; a `Logger` shows up in the device
    /// Console and in Xcode's log/organizer views, which matters for the failures logged below —
    /// both would otherwise leave the app silently running with an empty catalog.
    private static let logger = Logger(subsystem: "com.posix88.Voltly.Repository", category: "Repository")

    @MainActor
    public static var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Plug.self, Country.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            // `Country`/`Plug` are a read-only catalog reseeded from bundled JSON in
            // `preloadData()` — never user-generated data — so an unopenable store (a corrupted
            // file, or an install stuck on a schema version with no migration path from here) is
            // recoverable by discarding it and starting fresh, rather than a hard `fatalError`
            // that would crash every subsequent launch with no way out.
            logger.fault("Could not open ModelContainer, discarding the store and recreating: \(error)")
            assertionFailure("Could not open ModelContainer, discarding the store and recreating: \(error)")
            removeDefaultStore()

            do {
                return try ModelContainer(
                    for: Plug.self, Country.self,
                    migrationPlan: MigrationPlan.self
                )
            } catch {
                fatalError("Could not create ModelContainer even after discarding the existing store: \(error)")
            }
        }
    }()

    /// Deletes the default SwiftData store file (and its `-wal`/`-shm` sidecars) so the next
    /// `ModelContainer` creation starts from an empty, unmigrated store. Safe only because the
    /// data this container holds is a reseedable catalog, not user content.
    private static func removeDefaultStore() {
        let storeURL = ModelConfiguration().url
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(atPath: storeURL.path + suffix)
        }
    }

    @MainActor
    public static func preloadData() {
        do {
            // Check we haven't already added our users.
            let descriptor = FetchDescriptor<Country>()
            let existingCountries = try sharedModelContainer.mainContext.fetchCount(descriptor)
            guard existingCountries == 0 else {
                return
            }

            // Get the bundle for this Swift Package
            let bundle = Bundle.module

            // Load and decode the JSON.
            guard let urlcountries = bundle.url(forResource: "countries", withExtension: "json") else {
                fatalError("Failed to find countries.json")
            }
            guard let plugsurl = bundle.url(forResource: "plugs", withExtension: "json") else {
                fatalError("Failed to find plugs.json")
            }

            let dataplugs = try Data(contentsOf: plugsurl)
            let plugsData = try JSONDecoder().decode([PlugDecodable].self, from: dataplugs)

            let datacountries = try Data(contentsOf: urlcountries)
            let countriesData = try JSONDecoder().decode([CountryDecodable].self, from: datacountries)

            // First, create all unique plugs and insert them
            var plugsDict: [String: Plug] = [:]
            for plugData in plugsData {
                let plug = Plug(
                    id: plugData.id,
                    images: plugData.images,
                    specifications: plugData.specifications
                )
                plugsDict[plugData.id] = plug
                sharedModelContainer.mainContext.insert(plug)
            }

            // Then create countries and establish relationships
            for countryData in countriesData {
                let country = Country(
                    code: countryData.code,
                    voltage: countryData.voltage,
                    frequency: countryData.frequency,
                    flagUnicode: countryData.flagUnicode
                )
                sharedModelContainer.mainContext.insert(country)

                // Establish bidirectional relationships
                for plugTypeId in countryData.plugTypes {
                    if let plug = plugsDict[plugTypeId] {
                        country.plugs.append(plug)
                        plug.countries.append(country)
                    }
                }
            }

            // Save the context to persist changes
            try sharedModelContainer.mainContext.save()

        } catch {
            logger.error("Failed to pre-seed database: \(error.localizedDescription)")
        }
    }

    @MainActor
    public static func cleanDataBase() throws {
        let countries = try sharedModelContainer.mainContext.fetch(FetchDescriptor<Country>())
        let plugs = try sharedModelContainer.mainContext.fetch(FetchDescriptor<Plug>())
        for country in countries {
            sharedModelContainer.mainContext.delete(country)
        }
        for plug in plugs {
            sharedModelContainer.mainContext.delete(plug)
        }
        try sharedModelContainer.mainContext.save()
    }
}
