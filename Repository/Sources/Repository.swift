import Foundation
import os
import SwiftData

// MARK: - Repository

public enum Repository {
    /// `print` output is easy to miss outside a debugger; a `Logger` shows up in the device
    /// Console and in Xcode's log/organizer views, which matters for the failures logged below —
    /// both would otherwise leave the app silently running with an empty catalog.
    private static let logger = Logger(subsystem: "com.posix88.Voltly.Repository", category: "Repository")
    private static let countryCatalogVersionDefaultsKey = "countryCatalogVersion"

    /// There is deliberately no `VersionedSchema`/`SchemaMigrationPlan` here. `Country`/`Plug`
    /// are a read-only catalog reseeded from bundled JSON in `preloadData()` — never
    /// user-generated data — so the cheapest correct answer to any schema change is to discard
    /// the store and reseed, which is exactly what the recovery path below does. Introduce real
    /// versioning only if this container ever starts holding data that can't be regenerated.
    @MainActor
    public static var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Plug.self, Country.self)
        } catch {
            // An unopenable store (a corrupted file, or one written by an older model layout) is
            // recoverable by discarding it and starting fresh, rather than a hard `fatalError`
            // that would crash every subsequent launch with no way out. No `assertionFailure`
            // here on purpose: hitting this path is expected — not a programmer error — every
            // time the model layout changes, and trapping the debugger on a failure the code
            // then correctly recovers from is pure noise.
            logger.fault("Could not open ModelContainer, discarding the store and recreating: \(error)")
            removeDefaultStore()

            do {
                return try ModelContainer(for: Plug.self, Country.self)
            } catch {
                fatalError("Could not create ModelContainer even after discarding the existing store: \(error)")
            }
        }
    }()

    /// Deletes the default SwiftData store file (and its `-wal`/`-shm` sidecars) so the next
    /// `ModelContainer` creation starts from an empty store. Safe only because the data this
    /// container holds is a reseedable catalog, not user content.
    private static func removeDefaultStore() {
        let storeURL = ModelConfiguration().url
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(atPath: storeURL.path + suffix)
        }
    }

    @MainActor
    public static func preloadData(defaults: UserDefaults = .standard) {
        do {
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
            let countryCatalog = try JSONDecoder().decode(CountryCatalogDecodable.self, from: datacountries)

            let existingCountries = try sharedModelContainer.mainContext.fetchCount(FetchDescriptor<Country>())
            let storedVersion = defaults.object(forKey: countryCatalogVersionDefaultsKey) as? Int
            guard existingCountries == 0 || storedVersion != countryCatalog.version else {
                return
            }

            // The catalog is bundled reference data; only it is stored in this
            // container. A version change can therefore safely replace every
            // country and plug while user preferences remain in their own stores.
            if existingCountries > 0 {
                try cleanDataBase()
            }

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
            for countryData in countryCatalog.countries {
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
            defaults.set(countryCatalog.version, forKey: countryCatalogVersionDefaultsKey)

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
