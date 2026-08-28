import AppIntentsTesting
import Testing
@testable import WorldPlug

// MARK: - AppIntentsIntegrationTests

@Suite("App Intents integration", .serialized)
struct AppIntentsIntegrationTests {
    private let definitions = IntentDefinitions(bundleIdentifier: "com.posix88.Voltly")

    @Test("country power intent accepts an exported country reference")
    func countryPowerIntentAcceptsCountryReference() throws {
        let metadataEntity = definitions.entities["CountryEntity"].makeReference(identifier: "IT")
        let intent = definitions.intents["GetCountryPowerIntent"].makeIntent(country: metadataEntity)
        let country: AnyAppEntity = try intent.country

        #expect(intent.identifier == "GetCountryPowerIntent")
        #expect(country == metadataEntity)
    }

    @Test("device compatibility parameters are exported with stable identifiers")
    func deviceCompatibilityParametersAreExported() throws {
        let metadataEntity = definitions.entities["CountryEntity"].makeReference(identifier: "IT")
        let intent = definitions.intents["CheckDeviceCompatibilityIntent"].makeIntent(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            inputFrequency: "50/60 Hz",
            destination: metadataEntity
        )
        let deviceName: String = try intent.deviceName
        let inputVoltage: String = try intent.inputVoltage
        let inputFrequency: String? = try intent.inputFrequency
        let destination: AnyAppEntity = try intent.destination

        #expect(deviceName == "Charger")
        #expect(inputVoltage == "100-240 V")
        #expect(inputFrequency == "50/60 Hz")
        #expect(destination == metadataEntity)
    }

    @Test("device frequency remains optional in exported metadata")
    func deviceFrequencyRemainsOptional() throws {
        let metadataEntity = definitions.entities["CountryEntity"].makeReference(identifier: "IT")
        let intent = definitions.intents["CheckDeviceCompatibilityIntent"].makeIntent(
            deviceName: "Charger",
            inputVoltage: "100-240 V",
            destination: metadataEntity
        )
        let inputFrequency: String? = try intent.inputFrequency

        #expect(inputFrequency == nil)
    }

    @Test("next trip requirements intent is exported")
    func nextTripRequirementsIntentIsExported() {
        let intent = definitions.intents["GetNextTripRequirementsIntent"].makeIntent()

        #expect(intent.identifier == "GetNextTripRequirementsIntent")
    }
}
