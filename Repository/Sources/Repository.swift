import SwiftData
import Foundation

public typealias Plug = SchemaV2.Plug
public typealias Country = SchemaV2.Country

public final class Repository {

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
    static public func preloadData() {
        do {
            // Check we haven't already added our users.
            let descriptor = FetchDescriptor<Country>()
            let existingCountries = try sharedModelContainer.mainContext.fetchCount(descriptor)
            guard existingCountries == 0 else { return }

            // Get the bundle for this class
            let bundle = Bundle(for: Repository.self)
            
            // Load and decode the JSON.
            guard let urlcountries = bundle.url(forResource: "countries", withExtension: "json") else {
                fatalError("Failed to find countries.json")
            }
            // Load and decode the JSON.
            guard let plugsurl = bundle.url(forResource: "plugs", withExtension: "json") else {
                fatalError("Failed to find plugs.json")
            }

            let dataplugs = try Data(contentsOf: plugsurl)
            let plugs = try JSONDecoder().decode([PlugDecodable].self, from: dataplugs)

            let datacountries = try Data(contentsOf: urlcountries)
            let countries = try JSONDecoder().decode([CountryDecodable].self, from: datacountries)

            // Add all our data to the context.
            for country in countries {
                let db = Country(code: country.code, voltage: country.voltage, frequency: country.frequency, flagUnicode: country.flagUnicode)
                sharedModelContainer.mainContext.insert(db)
                db.plugs = plugs.filter { country.plugTypes.contains($0.id) }.map { Plug(id: $0.id, name: $0.name, shortInfo: $0.shortInfo, info: $0.info, images: $0.images) }
            }
        } catch {
            print("Failed to pre-seed database. \(error.localizedDescription)")
        }
    }

    @MainActor
    static public func cleanDataBase() throws {
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
