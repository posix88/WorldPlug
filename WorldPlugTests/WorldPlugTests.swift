import Foundation
import Repository
import Testing
@testable import WorldPlug

// MARK: - VoltlyDeepLinkTests

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

// MARK: - AppNavigationModelTests

@Suite("AppNavigationModel")
@MainActor
struct AppNavigationModelTests {
    @Test("opening a country routes to its detail")
    func openCountryRoutesToDetail() {
        let navigationModel = AppNavigationModel.shared
        navigationModel.selectedTab = .saved
        navigationModel.deepLinkedCountryCode = nil

        navigationModel.openCountry(code: "it")

        #expect(navigationModel.selectedTab == .countries)
        #expect(navigationModel.deepLinkedCountryCode == "IT")
    }
}

// MARK: - CountryEntityTests

@Suite("CountryEntity")
@MainActor
struct CountryEntityTests {
    @Test("entity exposes rich electrical metadata")
    func exposesRichElectricalMetadata() {
        let plug = Plug(
            id: "C",
            images: [],
            specifications: PlugSpecifications(
                pinDiameter: "",
                pinSpacing: "",
                ratedAmperage: "",
                alsoKnownAs: ""
            )
        )
        let entity = CountryEntity(
            country: Country(
                code: "IT",
                voltage: "230V",
                frequency: "50Hz",
                flagUnicode: "🇮🇹",
                plugs: [plug]
            ),
            locale: Locale(identifier: "en_US")
        )

        #expect(entity.voltage == "230V")
        #expect(entity.frequency == "50Hz")
        #expect(entity.plugTypes == ["C"])
        #expect(entity.electricalInformation.contains("230V"))
    }
}
