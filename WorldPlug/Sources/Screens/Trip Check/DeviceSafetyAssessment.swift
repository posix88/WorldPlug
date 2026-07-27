import Repository

enum DeviceSafetyStatus: CaseIterable {
    case ready
    case adapterNeeded
    case checkLabel
    case unsafe

    var title: String {
        switch self {
        case .ready: LocalizationKeys.tripCheckStatusReady.localized
        case .adapterNeeded: LocalizationKeys.tripCheckStatusAdapter.localized
        case .checkLabel: LocalizationKeys.tripCheckStatusCheckLabel.localized
        case .unsafe: LocalizationKeys.tripCheckStatusUnsafe.localized
        }
    }

    var symbolName: String {
        switch self {
        case .ready: "checkmark.seal.fill"
        case .adapterNeeded: "powerplug.fill"
        case .checkLabel: "exclamationmark.triangle.fill"
        case .unsafe: "xmark.octagon.fill"
        }
    }
}

struct DeviceSafetyAssessment: Identifiable {
    let device: TravelDevice
    let status: DeviceSafetyStatus
    let message: String

    var id: TravelDevice { device }
}

enum TripSafetyChecker {
    static func assessments(
        devices: [TravelDevice],
        homeCountry: Country?,
        destination: Country
    ) -> [DeviceSafetyAssessment] {
        devices.map { assessment(for: $0, homeCountry: homeCountry, destination: destination) }
    }

    private static func assessment(
        for device: TravelDevice,
        homeCountry: Country?,
        destination: Country
    ) -> DeviceSafetyAssessment {
        guard let homeCountry else {
            return DeviceSafetyAssessment(
                device: device,
                status: .checkLabel,
                message: LocalizationKeys.tripCheckMessageSetHome.localized
            )
        }

        let sameVoltage = VoltageCompatibility.isCompatible(homeCountry.voltage, destination.voltage)
        let plugMatches = !Set(homeCountry.plugs.map(\.id)).isDisjoint(with: destination.plugs.map(\.id))

        if sameVoltage, plugMatches {
            return DeviceSafetyAssessment(
                device: device,
                status: .ready,
                message: LocalizationKeys.tripCheckMessageReady.localized
            )
        }

        if device.isUsuallyDualVoltage {
            return DeviceSafetyAssessment(
                device: device,
                status: .adapterNeeded,
                message: LocalizationKeys.tripCheckMessageDualVoltage.localized(destination.voltage)
            )
        }

        return DeviceSafetyAssessment(
            device: device,
            status: sameVoltage ? .adapterNeeded : .unsafe,
            message: sameVoltage
                ? LocalizationKeys.tripCheckMessageAdapter.localized
                : LocalizationKeys.tripCheckMessageUnsafe.localized(destination.voltage)
        )
    }
}
