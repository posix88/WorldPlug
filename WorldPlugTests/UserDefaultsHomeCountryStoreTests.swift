import Foundation
import Testing
@testable import WorldPlug

struct UserDefaultsHomeCountryStoreTests {
    @Test
    func migratesLegacyValueIntoSharedDefaults() {
        let suiteName = "UserDefaultsHomeCountryStoreTests.shared"
        let legacySuiteName = "UserDefaultsHomeCountryStoreTests.legacy"
        let sharedDefaults = UserDefaults(suiteName: suiteName)!
        let legacyDefaults = UserDefaults(suiteName: legacySuiteName)!
        let key = "home.country.code"

        sharedDefaults.removePersistentDomain(forName: suiteName)
        legacyDefaults.removePersistentDomain(forName: legacySuiteName)
        legacyDefaults.set("IT", forKey: key)

        let store = UserDefaultsHomeCountryStore(defaults: sharedDefaults, legacyDefaults: legacyDefaults)

        #expect(store.homeCountryCode == "IT")
        #expect(sharedDefaults.string(forKey: key) == "IT")
    }
}
