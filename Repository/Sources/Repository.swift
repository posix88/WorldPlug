import Foundation
import SwiftData

public typealias Plug = SchemaV2.Plug
public typealias Country = SchemaV2.Country

// MARK: - Repository

public enum Repository {
    @MainActor
    public static var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Plug.self, Country.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
                    name: plugData.name,
                    shortInfo: plugData.shortInfo,
                    info: plugData.info,
                    images: plugData.images
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
            print("Failed to pre-seed database. \(error.localizedDescription)")
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
    }
}
