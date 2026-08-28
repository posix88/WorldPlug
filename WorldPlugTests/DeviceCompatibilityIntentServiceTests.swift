import Foundation
import Repository
import SwiftData
import Testing
@testable import WorldPlug

// MARK: - DeviceCompatibilityIntentServiceTests

@Suite("Device compatibility intent service", .serialized)
@MainActor
struct DeviceCompatibilityIntentServiceTests {
    @Test("returns ready for matching electricity and plugs")
    func returnsReady() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .ready)
    }

    @Test("requires adapter when plugs differ")
    func requiresAdapter() throws {
        let fixtures = try makeFixtures(homePlug: "A", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .adapterNeeded)
    }

    @Test("rejects incompatible voltage")
    func rejectsIncompatibleVoltage() throws {
        let fixtures = try makeFixtures(homePlug: "A", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Hair dryer",
            inputVoltage: "120 V",
            inputFrequency: "60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .unsafe)
    }

    @Test("rejects device that supports only one destination voltage")
    func rejectsPartialDestinationVoltageSupport() throws {
        let fixtures = try makeFixtures(
            homePlug: "C",
            destinationPlug: "C",
            destinationVoltage: "127 V / 220 V"
        )

        let result = try fixtures.service.assess(
            deviceName: "Hair dryer",
            inputVoltage: "120 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .unsafe)
    }

    @Test("accepts universal voltage range for every destination supply")
    func acceptsUniversalVoltageRange() throws {
        let fixtures = try makeFixtures(
            homePlug: "C",
            destinationPlug: "C",
            destinationVoltage: "127 V / 220 V"
        )

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .ready)
    }

    @Test("requires label check for missing voltage")
    func requiresLabelCheck() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "",
            inputFrequency: nil,
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .checkLabel)
    }

    @Test("requires label check for incompatible frequency")
    func requiresLabelCheckForFrequency() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Clock",
            inputVoltage: "220-240 V",
            inputFrequency: "60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .checkLabel)
    }

    @Test("requires label check when device supports only one destination frequency")
    func rejectsPartialDestinationFrequencySupport() throws {
        let fixtures = try makeFixtures(
            homePlug: "C",
            destinationPlug: "C",
            destinationFrequency: "50 Hz / 60 Hz"
        )

        let result = try fixtures.service.assess(
            deviceName: "Clock",
            inputVoltage: "100-240 V",
            inputFrequency: "50 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .checkLabel)
    }

    @Test("requires device frequency before a safe recommendation")
    func requiresDeviceFrequency() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: nil,
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .frequencyRequired)
    }

    @Test("does not claim ready without a home country")
    func requiresHomeCountryForPlugCheck() throws {
        let fixtures = try makeFixtures(homePlug: nil, destinationPlug: "C")

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .homeCountryRequired)
    }

    @Test("shared checker requires home country before reporting ready")
    func sharedCheckerRequiresHomeCountry() throws {
        let fixtures = try makeFixtures(homePlug: nil, destinationPlug: "C")
        let device = PackDevice(name: "Charger", voltage: "100-240 V", frequency: "50/60 Hz")

        let assessment = try #require(
            TripSafetyChecker.assessments(
                devices: [device],
                homeCountry: nil,
                destination: fixtures.destination
            ).first
        )

        #expect(assessment.status == .homeCountryRequired)
    }

    @Test("requires adapter when only some home plug types match")
    func requiresAdapterForPartialPlugOverlap() throws {
        let fixtures = try makeFixtures(
            homePlug: "C",
            destinationPlug: "C",
            additionalHomePlugs: ["N"]
        )

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: fixtures.destinationEntity
        )

        #expect(result.recommendation == .adapterNeeded)
    }

    @Test("does not treat mixed home supply as universal device support")
    func rejectsMixedHomeSupplyAsUniversalSupport() {
        #expect(!VoltageCompatibility.isCompatible("127 V / 220 V", "230 V"))
    }

    @Test("uses repository destination values")
    func usesRepositoryDestinationValues() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")
        let staleEntity = fixtures.destinationEntity
        staleEntity.voltage = "120 V"
        staleEntity.frequency = "60 Hz"

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destinationEntity: staleEntity
        )

        #expect(result.destinationVoltage == "230 V")
        #expect(result.destinationFrequency == "50 Hz")
        #expect(result.destinationPlugTypes == ["C"])
    }

    @Test("reports unavailable destination")
    func reportsUnavailableDestination() throws {
        let fixtures = try makeFixtures(homePlug: "C", destinationPlug: "C")
        let missingEntity = fixtures.destinationEntity
        missingEntity.code = "ZZ"

        let result = try fixtures.service.assess(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: nil,
            destinationEntity: missingEntity
        )

        #expect(result.recommendation == .destinationUnavailable)
    }

    @Test("unsafe dialog leads with a prohibition")
    func unsafeDialogLeadsWithProhibition() {
        let result = makeResult(recommendation: .unsafe)

        let answer = DeviceCompatibilityAnswer(
            result: result,
            locale: Locale(identifier: "en")
        )

        #expect(answer.text.hasPrefix("Do not plug"))
    }

    @Test("missing home dialog never claims ready")
    func missingHomeDialogDoesNotClaimReady() {
        let result = makeResult(recommendation: .homeCountryRequired)

        let answer = DeviceCompatibilityAnswer(
            result: result,
            locale: Locale(identifier: "en")
        )

        #expect(answer.text.contains("Set your home country"))
        #expect(!answer.text.localizedCaseInsensitiveContains("ready"))
    }

    @Test("unsafe dialog is localized in Italian")
    func unsafeDialogIsLocalizedInItalian() {
        let result = makeResult(recommendation: .unsafe)

        let answer = DeviceCompatibilityAnswer(
            result: result,
            locale: Locale(identifier: "it")
        )

        #expect(answer.text.hasPrefix("Non collegare"))
    }

    private func makeFixtures(
        homePlug: String?,
        destinationPlug: String,
        destinationVoltage: String = "230 V",
        destinationFrequency: String = "50 Hz",
        additionalHomePlugs: [String] = []
    ) throws -> (
        container: ModelContainer,
        service: DeviceCompatibilityIntentService,
        destinationEntity: CountryEntity,
        destination: Country
    ) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Country.self,
            Plug.self,
            configurations: configuration
        )
        let destinationPlugModel = makePlug(destinationPlug)
        let destination = Country(
            code: "IT",
            voltage: destinationVoltage,
            frequency: destinationFrequency,
            flagUnicode: "🇮🇹",
            plugs: [destinationPlugModel]
        )
        container.mainContext.insert(destination)

        if let homePlug {
            container.mainContext.insert(
                Country(
                    code: "US",
                    voltage: "120 V",
                    frequency: "60 Hz",
                    flagUnicode: "🇺🇸",
                    plugs: ([homePlug] + additionalHomePlugs).map {
                        $0 == destinationPlug ? destinationPlugModel : makePlug($0)
                    }
                )
            )
        }
        try container.mainContext.save()

        let store = HomeCountryStoreStub(homeCountryCode: homePlug == nil ? "" : "US")
        return (
            container,
            DeviceCompatibilityIntentService(
                modelContext: container.mainContext,
                homeCountryStore: store
            ),
            CountryEntity(country: destination, locale: Locale(identifier: "en_US")),
            destination
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

    private func makeResult(
        recommendation: DeviceCompatibilityRecommendation
    ) -> DeviceCompatibilityResult {
        DeviceCompatibilityResult(
            recommendation: recommendation,
            deviceName: "Hair dryer",
            destinationName: "Italy",
            destinationVoltage: "230 V",
            destinationFrequency: "50 Hz",
            destinationPlugTypes: ["C", "F", "L"],
            explanation: "The voltage is incompatible."
        )
    }
}

// MARK: - HomeCountryStoreStub

private final class HomeCountryStoreStub: HomeCountryStoring {
    var homeCountryCode: String

    init(homeCountryCode: String) {
        self.homeCountryCode = homeCountryCode
    }
}
