import Foundation
import Repository
import Testing
@testable import WorldPlug

// MARK: - CountryPowerAnswerTests

@Suite("Country power answer", .serialized)
@MainActor
struct CountryPowerAnswerTests {
    @Test("formats complete electrical information")
    func formatsCompleteElectricalInformation() {
        let country = Country(
            code: "IT",
            voltage: "230 V",
            frequency: "50 Hz",
            flagUnicode: "🇮🇹",
            plugs: [
                Plug(id: "C", images: [], specifications: .empty),
                Plug(id: "F", images: [], specifications: .empty),
                Plug(id: "L", images: [], specifications: .empty)
            ]
        )
        let entity = CountryEntity(country: country, locale: Locale(identifier: "en_US"))

        let answer = CountryPowerAnswer(country: entity, locale: Locale(identifier: "en_US"))

        #expect(answer.text.contains("Italy"))
        #expect(answer.text.contains("230 V"))
        #expect(answer.text.contains("50 Hz"))
        #expect(answer.text.contains("C, F, and L"))
    }

    @Test("describes unavailable plug types")
    func describesUnavailablePlugTypes() {
        let country = Country(
            code: "IT",
            voltage: "230 V",
            frequency: "50 Hz",
            flagUnicode: "🇮🇹"
        )
        let entity = CountryEntity(country: country, locale: Locale(identifier: "en_US"))

        let answer = CountryPowerAnswer(country: entity, locale: Locale(identifier: "en_US"))

        #expect(answer.text.contains("Unavailable"))
    }

    @Test("formats Italian electrical information")
    func formatsItalianElectricalInformation() {
        let country = Country(
            code: "IT",
            voltage: "230 V",
            frequency: "50 Hz",
            flagUnicode: "🇮🇹",
            plugs: [
                Plug(id: "C", images: [], specifications: .empty),
                Plug(id: "F", images: [], specifications: .empty)
            ]
        )
        let locale = Locale(identifier: "it")
        let entity = CountryEntity(country: country, locale: locale)

        let answer = CountryPowerAnswer(country: entity, locale: locale)

        #expect(answer.text.contains("rete elettrica"), "Actual answer: \(answer.text)")
        #expect(answer.text.contains("C e F"), "Actual answer: \(answer.text)")
    }
}

private extension PlugSpecifications {
    static var empty: PlugSpecifications {
        PlugSpecifications(
            pinDiameter: "",
            pinSpacing: "",
            ratedAmperage: "",
            alsoKnownAs: ""
        )
    }
}
