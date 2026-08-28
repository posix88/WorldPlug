import AppIntents
import Repository

// MARK: - CheckDeviceCompatibilityIntent

struct CheckDeviceCompatibilityIntent: AppIntent {
    static let title = LocalizedStringResource(
        "intent.device.compatibility.title",
        defaultValue: "Check a device"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "intent.device.compatibility.description",
            defaultValue: "Check whether a device is safe to use at a destination."
        )
    )
    static let supportedModes: IntentModes = .background
    static let allowedExecutionTargets: IntentExecutionTargets = .main

    @Parameter(
        title: LocalizedStringResource(
            "intent.device.compatibility.device.parameter",
            defaultValue: "Device"
        )
    )
    var deviceName: String

    @Parameter(
        title: LocalizedStringResource(
            "intent.device.compatibility.voltage.parameter",
            defaultValue: "Input voltage"
        )
    )
    var inputVoltage: String

    @Parameter(
        title: LocalizedStringResource(
            "intent.device.compatibility.frequency.parameter",
            defaultValue: "Input frequency"
        )
    )
    var inputFrequency: String?

    @Parameter(
        title: LocalizedStringResource(
            "intent.device.compatibility.destination.parameter",
            defaultValue: "Destination"
        )
    )
    var destination: CountryEntity

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Check \(\.$deviceName) for \(\.$destination)") {
            \.$inputVoltage
            \.$inputFrequency
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DeviceCompatibilityRecommendation> & ProvidesDialog {
        let service = DeviceCompatibilityIntentService(
            modelContext: Repository.sharedModelContainer.mainContext,
            homeCountryStore: UserDefaultsHomeCountryStore()
        )
        let result = try service.assess(
            deviceName: deviceName,
            inputVoltage: inputVoltage,
            inputFrequency: inputFrequency,
            destinationEntity: destination
        )
        let answer = DeviceCompatibilityAnswer(result: result)
        return .result(value: result.recommendation, dialog: answer.dialog)
    }
}
