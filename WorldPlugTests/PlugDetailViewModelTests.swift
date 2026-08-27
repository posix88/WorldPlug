import Repository
import SwiftData
import Testing
@testable import WorldPlug

// MARK: - PlugDetailViewModelTests

@Suite("PlugDetailViewModel")
@MainActor
struct PlugDetailViewModelTests {
    private struct PlugFixture {
        let container: ModelContainer
        let plug: Plug
    }

    private func makePlug(
        id: String = "A",
        pinDiameter: String = "1.5mm",
        pinSpacing: String = "12.7mm",
        ratedAmperage: String = "15A"
    ) throws -> PlugFixture {
        let container = try ModelContainer(
            for: Plug.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let plug = Plug(
            id: id,
            images: [],
            specifications: .init(
                pinDiameter: pinDiameter,
                pinSpacing: pinSpacing,
                ratedAmperage: ratedAmperage,
                alsoKnownAs: "NEMA 1-15"
            )
        )
        container.mainContext.insert(plug)
        return PlugFixture(container: container, plug: plug)
    }

    // MARK: shareText

    @Test("shareText contains the plug type name")
    func shareTextContainsPlugTypeName() throws {
        let fixture = try makePlug(id: "A")
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(vm.shareText.contains("A"))
    }

    @Test("shareText contains the plug shortInfo")
    func shareTextContainsShortInfo() throws {
        let fixture = try makePlug(id: "A")
        let vm = PlugDetailViewModel(plug: fixture.plug)
        let expected = String(localized: fixture.plug.plugType.shortInfoResource)
        #expect(vm.shareText.contains(expected))
    }

    @Test("shareText contains pin diameter")
    func shareTextContainsPinDiameter() throws {
        let fixture = try makePlug(pinDiameter: "1.5mm")
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(vm.shareText.contains("1.5mm"))
    }

    @Test("shareText contains pin spacing")
    func shareTextContainsPinSpacing() throws {
        let fixture = try makePlug(pinSpacing: "12.7mm")
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(vm.shareText.contains("12.7mm"))
    }

    @Test("shareText contains rated amperage")
    func shareTextContainsRatedAmperage() throws {
        let fixture = try makePlug(ratedAmperage: "15A")
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(vm.shareText.contains("15A"))
    }

    @Test("shareText contains Socket Buddy branding")
    func shareTextContainsBranding() throws {
        let fixture = try makePlug()
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(vm.shareText.contains("Socket Buddy"))
    }

    @Test(
        "shareText is non-empty for all plug types",
        arguments: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O"]
    )
    func shareTextIsNonEmptyForAllTypes(id: String) throws {
        let fixture = try makePlug(id: id)
        let vm = PlugDetailViewModel(plug: fixture.plug)
        #expect(!vm.shareText.isEmpty)
    }
}
