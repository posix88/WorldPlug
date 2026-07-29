import Foundation
import Repository
import Testing
@testable import WorldPlug

// MARK: - WorldPlugTests
//
// App-target unit tests. Add test suites here for any type that lives
// in the WorldPlug target and cannot be moved to the Repository package.
//
// Example:
//   @Suite("PlugDetailViewModel")
//   @MainActor
//   struct PlugDetailViewModelTests { ... }

@Suite("VoltlyDeepLink")
struct VoltlyDeepLinkTests {
    @Test("country URL parses a normalized country code")
    func countryURLParsesCode() throws {
        let url = try #require(URL(string: "voltly://country/it"))

        #expect(VoltlyDeepLink.countryCode(from: url) == "IT")
    }

    @Test("unrelated URL is not treated as a Voltly route")
    func unrelatedURLIsRejected() throws {
        let url = try #require(URL(string: "https://example.com/country/IT"))

        #expect(VoltlyDeepLink.countryCode(from: url) == nil)
        #expect(VoltlyDeepLink.isPremiumURL(url) == false)
    }
}

@Suite("OpenCountryIntent")
@MainActor
struct OpenCountryIntentTests {
    @Test("perform routes the selected country through the coordinator")
    func performRoutesCountry() async throws {
        let navigationModel = AppNavigationModel.shared
        navigationModel.selectedTab = 2
        navigationModel.deepLinkedCountryCode = nil

        var intent = OpenCountryIntent()
        intent.target = CountryEntity(
            country: Country(
                code: "IT",
                voltage: "230V",
                frequency: "50Hz",
                flagUnicode: "🇮🇹"
            )
        )

        _ = try await intent.perform()

        #expect(navigationModel.selectedTab == 0)
        #expect(navigationModel.deepLinkedCountryCode == "IT")
    }
}
