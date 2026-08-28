import Foundation
import Repository
import Testing
@testable import WorldPlug

// MARK: - CountryEntityLocalizationTests

@Suite("Country entity localization")
@MainActor
struct CountryEntityLocalizationTests {
    @Test("Italian indexed description is fully localized")
    func italianIndexedDescriptionIsLocalized() {
        let entity = CountryEntity(
            country: makeCountry(),
            locale: Locale(identifier: "it")
        )

        #expect(entity.electricalInformation.contains("Italia usa 230 V a 50 Hz"))
        #expect(entity.electricalInformation.contains("Tipi di spina: C, F e L"))
        #expect(!entity.electricalInformation.contains("Plug types"))
    }

    @Test("Italian display subtitle localizes plug types")
    func italianDisplaySubtitleIsLocalized() {
        let entity = CountryEntity(
            country: makeCountry(),
            locale: Locale(identifier: "it")
        )

        let subtitle = entity.displayRepresentation.subtitle.map { String(localized: $0) }
        #expect(subtitle == "230 V · 50 Hz · Tipi di spina: C, F e L")
    }

    @Test("Spotlight signature changes with locale")
    func spotlightSignatureChangesWithLocale() {
        let english = CountrySpotlightIndex.catalogSignature(
            version: "1.0",
            locale: Locale(identifier: "en")
        )
        let italian = CountrySpotlightIndex.catalogSignature(
            version: "1.0",
            locale: Locale(identifier: "it")
        )

        #expect(english != italian)
    }

    @Test("system reindex bypasses matching launch signature")
    func systemReindexBypassesMatchingSignature() {
        #expect(
            CountrySpotlightIndex.shouldIndex(
                storedSignature: "1.0|it",
                currentSignature: "1.0|it",
                force: true
            )
        )
        #expect(
            !CountrySpotlightIndex.shouldIndex(
                storedSignature: "1.0|it",
                currentSignature: "1.0|it",
                force: false
            )
        )
    }

    private func makeCountry() -> Country {
        Country(
            code: "IT",
            voltage: "230 V",
            frequency: "50 Hz",
            flagUnicode: "🇮🇹",
            plugs: ["C", "F", "L"].map(makePlug)
        )
    }

    private func makePlug(_ id: String) -> Plug {
        Plug(
            id: id,
            images: [],
            specifications: PlugSpecifications(
                pinDiameter: "",
                pinSpacing: "",
                ratedAmperage: "",
                alsoKnownAs: ""
            )
        )
    }
}
