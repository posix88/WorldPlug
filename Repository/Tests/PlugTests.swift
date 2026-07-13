import Foundation
import SwiftData
import Testing

@testable import Repository

// MARK: - Plug Tests

@Suite("Plug")
@MainActor
struct PlugTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try makeContainer()
        context = container.mainContext
    }

    @Test("plugType is inferred correctly from id on init", arguments: PlugType.allCases.filter { $0 != .unknown })
    func plugTypeInference(type: PlugType) {
        let plug = makePlug(id: type.rawValue, context: context)
        #expect(plug.plugType == type)
    }

    @Test("Unknown id falls back to .unknown")
    func unknownPlugType() {
        let plug = makePlug(id: "Z", context: context)
        #expect(plug.plugType == .unknown)
    }

    @Test("Empty id falls back to .unknown")
    func emptyIdIsUnknown() {
        let plug = makePlug(id: "", context: context)
        #expect(plug.plugType == .unknown)
    }

    @Test("Lowercase id does not match — plug types are uppercase")
    func lowercaseIdIsUnknown() {
        let plug = makePlug(id: "a", context: context)
        #expect(plug.plugType == .unknown)
    }

    @Test("id is stored unchanged")
    func idIsStored() {
        let plug = makePlug(id: "G", context: context)
        #expect(plug.id == "G")
    }

    @Test("images array is stored as provided")
    func imagesStored() {
        let urls = [
            URL(string: "https://example.com/plug-a.png")!,
            URL(string: "https://example.com/plug-b.png")!
        ]
        let plug = Plug(
            id: "A",
            images: urls,
            specifications: makeSpecs()
        )
        context.insert(plug)
        #expect(plug.images == urls)
    }

    @Test("Specification fields are flattened onto the model")
    func specsFlattened() {
        let specs = makeSpecs(pinDiameter: "4.8mm", pinSpacing: "19mm", ratedAmperage: "13A", alsoKnownAs: "BS 1363")
        let plug = Plug(id: "G", images: [], specifications: specs)
        context.insert(plug)

        #expect(plug.pinDiameter == "4.8mm")
        #expect(plug.pinSpacing == "19mm")
        #expect(plug.ratedAmperage == "13A")
        #expect(plug.alsoKnownAs == "BS 1363")
    }
}
