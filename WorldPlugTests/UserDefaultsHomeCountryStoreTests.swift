import Foundation
import Testing
@testable import WorldPlug

struct UserDefaultsHomeCountryStoreTests {
    @Test
    func roundTripsAndClearsTheStoredCode() {
        let suiteName = "UserDefaultsHomeCountryStoreTests.shared"
        let defaults = UserDefaults(suiteName: suiteName)!
        let key = "home.country.code"

        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsHomeCountryStore(defaults: defaults)
        #expect(store.homeCountryCode.isEmpty)

        store.homeCountryCode = "IT"
        #expect(store.homeCountryCode == "IT")
        #expect(defaults.string(forKey: key) == "IT")

        store.homeCountryCode = ""
        #expect(store.homeCountryCode.isEmpty)
        #expect(defaults.string(forKey: key) == nil)
    }
}
