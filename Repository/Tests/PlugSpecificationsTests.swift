import Foundation
import Testing

@testable import Repository

// MARK: - PlugSpecifications Tests

@Suite("PlugSpecifications")
struct PlugSpecificationsTests {
    @Test("Codable round-trip preserves all fields")
    func codableRoundtrip() throws {
        let original = makeSpecs(
            pinDiameter: "4.8mm",
            pinSpacing: "19mm",
            ratedAmperage: "13A",
            alsoKnownAs: "BS 1363"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PlugSpecifications.self, from: data)

        #expect(decoded.pinDiameter == original.pinDiameter)
        #expect(decoded.pinSpacing == original.pinSpacing)
        #expect(decoded.ratedAmperage == original.ratedAmperage)
        #expect(decoded.alsoKnownAs == original.alsoKnownAs)
    }

    @Test("Encoded JSON uses snake_case keys")
    func snakeCaseKeys() throws {
        let data = try JSONEncoder().encode(makeSpecs())
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(json["pin_diameter"] != nil)
        #expect(json["pin_spacing"] != nil)
        #expect(json["rated_amperage"] != nil)
        #expect(json["also_known_as"] != nil)
        // Ensure camelCase keys are NOT present
        #expect(json["pinDiameter"] == nil)
        #expect(json["pinSpacing"] == nil)
    }

    @Test("Decodes correctly from snake_case JSON")
    func decodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "pin_diameter": "1.5mm",
            "pin_spacing": "12.7mm",
            "rated_amperage": "10A",
            "also_known_as": "NEMA 5-15"
        }
        """.data(using: .utf8)!

        let specs = try JSONDecoder().decode(PlugSpecifications.self, from: json)
        #expect(specs.pinDiameter == "1.5mm")
        #expect(specs.pinSpacing == "12.7mm")
        #expect(specs.ratedAmperage == "10A")
        #expect(specs.alsoKnownAs == "NEMA 5-15")
    }
}
