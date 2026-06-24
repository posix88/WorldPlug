import Foundation
import Testing

@testable import Repository

// MARK: - PlugType Tests

@Suite("PlugType")
struct PlugTypeTests {
    @Test("All 15 standard types A–O have correct uppercase raw values")
    func standardRawValues() {
        let expected = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O"]
        let standard = PlugType.allCases.filter { $0 != .unknown }
        #expect(standard.map(\.rawValue) == expected)
    }

    @Test("CaseIterable includes 16 cases: A–O plus .unknown")
    func allCasesCount() {
        #expect(PlugType.allCases.count == 16)
    }

    @Test(
        "Each letter A–O initialises to the correct case",
        arguments: zip(
            ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O"],
            [PlugType.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o]
        )
    )
    func rawValueMapping(rawValue: String, expected: PlugType) {
        #expect(PlugType(rawValue: rawValue) == expected)
    }

    @Test(".unknown has rawValue 'unknown'")
    func unknownRawValue() {
        #expect(PlugType.unknown.rawValue == "unknown")
    }

    @Test("Invalid raw values return nil")
    func invalidRawValue() {
        #expect(PlugType(rawValue: "Z") == nil)
        #expect(PlugType(rawValue: "") == nil)
        #expect(PlugType(rawValue: "a") == nil) // case-sensitive
        #expect(PlugType(rawValue: "1") == nil)
    }

    @Test("Codable round-trip preserves all cases", arguments: PlugType.allCases)
    func codableRoundtrip(plugType: PlugType) throws {
        let encoded = try JSONEncoder().encode(plugType)
        let decoded = try JSONDecoder().decode(PlugType.self, from: encoded)
        #expect(decoded == plugType)
    }
}
