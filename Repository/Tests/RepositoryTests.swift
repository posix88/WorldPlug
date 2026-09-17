@testable import Repository
import Foundation
import SwiftData
import Testing

// MARK: - Repository Tests

@Suite("Repository", .serialized)
@MainActor
struct RepositoryTests {
    // Tests run serially — all share the singleton sharedModelContainer.

    @Test("preloadData seeds at least one country")
    func preloadSeedsCountries() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let count = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Country>())
        #expect(count > 0)
    }

    @Test("preloadData refreshes the catalog when its bundled version changes")
    func preloadRefreshesVersionedCatalog() throws {
        let defaults = try #require(UserDefaults(suiteName: "RepositoryTests.catalogVersion"))
        defaults.removePersistentDomain(forName: "RepositoryTests.catalogVersion")
        defer { defaults.removePersistentDomain(forName: "RepositoryTests.catalogVersion") }

        try Repository.cleanDataBase()
        Repository.preloadData(defaults: defaults)

        let maldives = try #require(
            Repository.sharedModelContainer.mainContext
                .fetch(FetchDescriptor<Country>())
                .first(where: { $0.code == "MV" })
        )
        Repository.sharedModelContainer.mainContext.delete(maldives)
        try Repository.sharedModelContainer.mainContext.save()

        defaults.set(0, forKey: "countryCatalogVersion")
        Repository.preloadData(defaults: defaults)

        let refreshedMaldives = try Repository.sharedModelContainer.mainContext
            .fetch(FetchDescriptor<Country>())
            .first(where: { $0.code == "MV" })
        #expect(refreshedMaldives != nil)
    }

    @Test("preloadData seeds at least one plug")
    func preloadSeedsPlugs() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let count = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Plug>())
        #expect(count > 0)
    }

    @Test("preloadData is idempotent — country count does not change on second call")
    func preloadIsIdempotent() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let first = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Country>())

        Repository.preloadData() // second call — guard existingCountries == 0 should bail out
        let second = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Country>())

        #expect(first == second)
    }

    @Test("cleanDataBase removes all countries")
    func cleanRemovesCountries() throws {
        Repository.preloadData()
        try Repository.cleanDataBase()
        let count = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Country>())
        #expect(count == 0)
    }

    @Test("cleanDataBase removes all plugs")
    func cleanRemovesPlugs() throws {
        Repository.preloadData()
        try Repository.cleanDataBase()
        let count = try Repository.sharedModelContainer.mainContext
            .fetchCount(FetchDescriptor<Plug>())
        #expect(count == 0)
    }

    @Test("preloadData establishes country → plug relationships")
    func countriesToPlugsRelationship() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let countries = try Repository.sharedModelContainer.mainContext
            .fetch(FetchDescriptor<Country>())
        #expect(countries.filter { !$0.plugs.isEmpty }.isEmpty == false)
    }

    @Test("preloadData establishes plug → country relationships")
    func plugsToCountriesRelationship() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let plugs = try Repository.sharedModelContainer.mainContext
            .fetch(FetchDescriptor<Plug>())
        #expect(plugs.filter { !$0.countries.isEmpty }.isEmpty == false)
    }

    @Test("All seeded plugs have a valid non-.unknown PlugType")
    func seededPlugTypesAreValid() throws {
        try Repository.cleanDataBase()
        Repository.preloadData()
        let plugs = try Repository.sharedModelContainer.mainContext
            .fetch(FetchDescriptor<Plug>())
        #expect(plugs.filter { $0.plugType == .unknown }.isEmpty)
    }
}
