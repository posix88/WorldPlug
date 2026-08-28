import AppIntents

// MARK: - DeviceCompatibilityRecommendation

enum DeviceCompatibilityRecommendation: String, AppEnum, Sendable {
    case ready
    case adapterNeeded
    case homeCountryRequired
    case checkLabel
    case frequencyRequired
    case unsafe
    case destinationUnavailable

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.device.compatibility.recommendation.type",
            defaultValue: "Compatibility recommendation"
        )
    )

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .ready: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.ready",
                defaultValue: "Ready"
            )
        ),
        .adapterNeeded: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.adapter",
                defaultValue: "Adapter needed"
            )
        ),
        .homeCountryRequired: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.home.country",
                defaultValue: "Home country required"
            )
        ),
        .checkLabel: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.check.label",
                defaultValue: "Check device label"
            )
        ),
        .frequencyRequired: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.frequency.required",
                defaultValue: "Device frequency required"
            )
        ),
        .unsafe: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.unsafe",
                defaultValue: "Do not use"
            )
        ),
        .destinationUnavailable: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.device.compatibility.recommendation.destination.unavailable",
                defaultValue: "Destination unavailable"
            )
        )
    ]
}

// MARK: - DeviceCompatibilityResult

struct DeviceCompatibilityResult: Sendable {
    let recommendation: DeviceCompatibilityRecommendation
    let deviceName: String
    let destinationName: String
    let destinationVoltage: String
    let destinationFrequency: String
    let destinationPlugTypes: [String]
    let explanation: String
}
