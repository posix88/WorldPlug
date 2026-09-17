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
    public static let catalogDidRefreshNotification = Notification.Name("com.posix88.Voltly.catalogDidRefresh")

    /// There is deliberately no `VersionedSchema`/`SchemaMigrationPlan` here. `Country`/`Plug`
    /// are a read-only catalog refreshed from bundled JSON — never
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
            // Only a brand-new install needs a catalog before the first screen is built.
            // Existing installs retain their working catalog and refresh it asynchronously.
            let existingCountries = try sharedModelContainer.mainContext.fetchCount(FetchDescriptor<Country>())
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
            let countryCatalog = try JSONDecoder().decode(CountryCatalogDecodable.self, from: datacountries)

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

    /// Refreshes an existing catalog without blocking launch or temporarily emptying the store.
    /// Returns `true` when a newer bundled catalog was applied.
    @MainActor
    public static func refreshCatalogIfNeeded(
        in container: ModelContainer,
        defaults: UserDefaults = .standard
    ) async -> Bool {
        let storedVersion = defaults.object(forKey: countryCatalogVersionDefaultsKey) as? Int

        do {
            guard let refreshedVersion = try await CatalogRefreshActor(modelContainer: container)
                .refreshCatalogIfNeeded(storedVersion: storedVersion) else {
                return false
            }

            defaults.set(refreshedVersion, forKey: countryCatalogVersionDefaultsKey)
            return true
        } catch {
            logger.error("Failed to refresh catalog: \(error.localizedDescription)")
            return false
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

@ModelActor
private actor CatalogRefreshActor {
    func refreshCatalogIfNeeded(storedVersion: Int?) throws -> Int? {
        let bundle = Bundle.module
        guard let countriesURL = bundle.url(forResource: "countries", withExtension: "json"),
              let plugsURL = bundle.url(forResource: "plugs", withExtension: "json") else {
            throw CountrySnapshotRepositoryError.missingResource
        }

        let catalog = try JSONDecoder().decode(
            CountryCatalogDecodable.self,
            from: Data(contentsOf: countriesURL)
        )
        guard storedVersion != catalog.version else {
            return nil
        }

        let plugData = try JSONDecoder().decode([PlugDecodable].self, from: Data(contentsOf: plugsURL))
        let existingPlugs = try modelContext.fetch(FetchDescriptor<Plug>())
        var plugsByID = Dictionary(uniqueKeysWithValues: existingPlugs.map { ($0.id, $0) })

        for data in plugData {
            let plug: Plug
            if let existingPlug = plugsByID[data.id] {
                plug = existingPlug
            } else {
                let createdPlug = Plug(id: data.id, images: data.images, specifications: data.specifications)
                modelContext.insert(createdPlug)
                plugsByID[data.id] = createdPlug
                plug = createdPlug
            }
            plug.images = data.images
            plug.pinDiameter = data.specifications.pinDiameter
            plug.pinSpacing = data.specifications.pinSpacing
            plug.ratedAmperage = data.specifications.ratedAmperage
            plug.alsoKnownAs = data.specifications.alsoKnownAs
        }

        let existingCountries = try modelContext.fetch(FetchDescriptor<Country>())
        var countriesByCode = Dictionary(uniqueKeysWithValues: existingCountries.map { ($0.code, $0) })
        let bundledCodes = Set(catalog.countries.map(\.code))

        for data in catalog.countries {
            let country: Country
            if let existingCountry = countriesByCode[data.code] {
                country = existingCountry
            } else {
                let createdCountry = Country(
                    code: data.code,
                    voltage: data.voltage,
                    frequency: data.frequency,
                    flagUnicode: data.flagUnicode
                )
                modelContext.insert(createdCountry)
                countriesByCode[data.code] = createdCountry
                country = createdCountry
            }
            country.voltage = data.voltage
            country.frequency = data.frequency
            country.flagUnicode = data.flagUnicode
            country.plugs = data.plugTypes.compactMap { plugsByID[$0] }
        }

        for country in existingCountries where !bundledCodes.contains(country.code) {
            modelContext.delete(country)
        }

        try modelContext.save()
        return catalog.version
    }
}
