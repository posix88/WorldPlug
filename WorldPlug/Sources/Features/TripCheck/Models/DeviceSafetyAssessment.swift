import Foundation
import Repository

// MARK: - DeviceSafetyStatus

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
    let device: PackDevice
    let status: DeviceSafetyStatus
    let message: String

    var id: UUID { device.id }
}

enum TripSafetyChecker {
    static func assessments(
        devices: [PackDevice],
        homeCountry: Country?,
        destination: Country
    ) -> [DeviceSafetyAssessment] {
        devices.map { assessment(for: $0, homeCountry: homeCountry, destination: destination) }
    }

    private static func assessment(
        for device: PackDevice,
        homeCountry: Country?,
        destination: Country
    ) -> DeviceSafetyAssessment {
        guard !device.voltage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DeviceSafetyAssessment(
                device: device,
                status: .checkLabel,
                message: LocalizationKeys.tripCheckMessageMissingVoltage.localized
            )
        }

        guard VoltageCompatibility.isCompatible(device.voltage, destination.voltage) else {
            return DeviceSafetyAssessment(
                device: device,
                status: .unsafe,
                message: LocalizationKeys.tripCheckMessageUnsafe.localized(destination.voltage)
            )
        }

        if !device.frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !FrequencyCompatibility.isCompatible(device.frequency, destination.frequency) {
            return DeviceSafetyAssessment(
                device: device,
                status: .checkLabel,
                message: LocalizationKeys.tripCheckMessageFrequency.localized(destination.frequency)
            )
        }

        guard let homeCountry else {
            return DeviceSafetyAssessment(
                device: device,
                status: .ready,
                message: LocalizationKeys.tripCheckMessageReady.localized
            )
        }

        let plugMatches = !Set(homeCountry.plugs.map(\.id)).isDisjoint(with: destination.plugs.map(\.id))
        return DeviceSafetyAssessment(
            device: device,
            status: plugMatches ? .ready : .adapterNeeded,
            message: plugMatches
                ? LocalizationKeys.tripCheckMessageReady.localized
                : LocalizationKeys.tripCheckMessageAdapter.localized
        )
    }
}

private enum FrequencyCompatibility {
    static func isCompatible(_ lhs: String, _ rhs: String, tolerance: Int = 1) -> Bool {
        let lhsValues = values(in: lhs)
        let rhsValues = values(in: rhs)
        guard !lhsValues.isEmpty, !rhsValues.isEmpty else { return true }
        return lhsValues.contains { lhsValue in
            rhsValues.contains { abs($0 - lhsValue) <= tolerance }
        }
    }

    private static func values(in string: String) -> [Int] {
        string.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}
