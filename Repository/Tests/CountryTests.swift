import SwiftData
import Testing

@testable import Repository

// MARK: - Country Tests

@Suite("Country")
@MainActor
struct CountryTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try makeContainer()
        context = container.mainContext
    }

    @Test("code is stored unchanged")
    func codeIsStored() {
        let country = makeCountry(code: "IT", context: context)
        #expect(country.code == "IT")
    }

    @Test("id equals code (Identifiable)")
    func idEqualsCode() {
        let country = makeCountry(code: "GB", context: context)
        #expect(country.id == country.code)
    }

    @Test("localized name is derived from a known country code")
    func nameIsLocalised() {
        let country = makeCountry(code: "IT", context: context)
        #expect(country.localizedName(in: Locale(identifier: "en_US")).isEmpty == false)
    }

    @Test("unknown country code has a display fallback")
    func unknownCodeProducesFallbackName() {
        let country = makeCountry(code: "ZZ", context: context)
        #expect(country.localizedName(in: Locale(identifier: "en_US")).isEmpty == false)
    }

    @Test("voltage and frequency are stored as provided")
    func electricalSpecsStored() {
        let country = makeCountry(code: "US", voltage: "120V", frequency: "60Hz", context: context)
        #expect(country.voltage == "120V")
        #expect(country.frequency == "60Hz")
    }

    @Test("sortedPlugs returns empty array when country has no plugs")
    func sortedPlugsEmpty() {
        let country = makeCountry(code: "XX", context: context)
        #expect(country.sortedPlugs.isEmpty)
    }

    @Test("sortedPlugs returns plugs in ascending id order")
    func sortedPlugsOrdering() {
        let country = makeCountry(code: "DE", context: context)
        for id in ["F", "C", "A", "E"] {
            let plug = makePlug(id: id, context: context)
            country.plugs.append(plug)
            plug.countries.append(country)
        }
        #expect(country.sortedPlugs.map(\.id) == ["A", "C", "E", "F"])
    }

    @Test("sortedPlugs is stable for a single plug")
    func sortedPlugsSingleElement() {
        let country = makeCountry(code: "CH", context: context)
        let plug = makePlug(id: "J", context: context)
        country.plugs.append(plug)

        #expect(country.sortedPlugs.count == 1)
        #expect(country.sortedPlugs.first?.id == "J")
    }

    @Test("sortedPlugs reflects plugs appended after init")
    func sortedPlugsAfterAppend() {
        let country = makeCountry(code: "FR", context: context)
        let plugE = makePlug(id: "E", context: context)
        let plugC = makePlug(id: "C", context: context)
        country.plugs.append(plugE)
        country.plugs.append(plugC)

        #expect(country.sortedPlugs.map(\.id) == ["C", "E"])
    }
}
