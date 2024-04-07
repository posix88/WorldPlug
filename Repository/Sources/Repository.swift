import SwiftData
import Foundation

public final class Repository {
    public static let shared : Repository = Repository()

    public static var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Plug.self, Country.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @MainActor
    static public func preloadCountries() {
        do {
            // Check we haven't already added our users.
            let descriptor = FetchDescriptor<Country>()
            let existingCountries = try sharedModelContainer.mainContext.fetchCount(descriptor)
            guard existingCountries == 0 else { return }

            // Load and decode the JSON.
            guard let url = RepositoryIOSResources.bundle.url(forResource: "countries", withExtension: "json") else {
                fatalError("Failed to find users.json")
            }

            let data = try Data(contentsOf: url)
            let countries = try JSONDecoder().decode([Country].self, from: data)

            // Add all our data to the context.
            for country in countries {
                sharedModelContainer.mainContext.insert(country)
            }
        } catch {
            print("Failed to pre-seed database.")
        }
    }

    @MainActor
    static public func preloadPlugs() {
        do {
            // Check we haven't already added our users.
            let descriptor = FetchDescriptor<Plug>()
            let existingPlugs = try sharedModelContainer.mainContext.fetchCount(descriptor)
            guard existingPlugs == 0 else { return }

            // Load and decode the JSON.
            guard let url = RepositoryIOSResources.bundle.url(forResource: "plugs", withExtension: "json") else {
                fatalError("Failed to find users.json")
            }

            let data = try Data(contentsOf: url)
            let plugs = try JSONDecoder().decode([Plug].self, from: data)

            // Add all our data to the context.
            for plug in plugs {
                sharedModelContainer.mainContext.insert(plug)
            }
        } catch {
            print("Failed to pre-seed database.")
        }
    }


    @MainActor
    public static func allPlugsByIDs(_ id: [String]) -> [Plug] {
        let descriptor = FetchDescriptor(predicate: #Predicate { plug in
            id.contains(plug.id)
        }, sortBy: [SortDescriptor(\Plug.id)])

        do {
            return try sharedModelContainer.mainContext.fetch(descriptor)
        } catch {
            return []
        }
    }
}
