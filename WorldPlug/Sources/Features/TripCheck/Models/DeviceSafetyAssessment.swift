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

// MARK: - DeviceSafetyAssessment

struct DeviceSafetyAssessment: Identifiable {
    let device: PackDevice
    let status: DeviceSafetyStatus
    let message: String

    var id: UUID { device.id }
}

// MARK: - TripSafetyChecker

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
        let trimmedVoltage = device.voltage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedVoltage.isEmpty, VoltageCompatibility.hasRecognizedValue(trimmedVoltage) else {
            // Empty AND unparseable/garbled both mean the same thing here: we don't actually
            // know the device's input voltage, so we must not fall through to `isCompatible`,
            // which treats "nothing to compare" as compatible — the right default for a general
            // country-vs-country comparison, but the wrong one for a safety verdict, where
            // "unreadable" must never be reported as "safe".
            return DeviceSafetyAssessment(
                device: device,
                status: .checkLabel,
                message: LocalizationKeys.tripCheckMessageMissingVoltage.localized
            )
        }
        guard VoltageCompatibility.isCompatible(trimmedVoltage, destination.voltage) else {
            return DeviceSafetyAssessment(
                device: device,
                status: .unsafe,
                message: LocalizationKeys.tripCheckMessageUnsafe.localized(destination.voltage)
            )
        }

        let trimmedFrequency = device.frequency.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFrequency.isEmpty {
            let isRecognizedAndCompatible = FrequencyCompatibility.hasRecognizedValue(trimmedFrequency)
                && FrequencyCompatibility.isCompatible(trimmedFrequency, destination.frequency)
            if !isRecognizedAndCompatible {
                return DeviceSafetyAssessment(
                    device: device,
                    status: .checkLabel,
                    message: LocalizationKeys.tripCheckMessageFrequency.localized(destination.frequency)
                )
            }
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

// MARK: - FrequencyCompatibility

private enum FrequencyCompatibility {
    static func isCompatible(_ lhs: String, _ rhs: String, tolerance: Int = 1) -> Bool {
        let lhsValues = values(in: lhs)
        let rhsValues = values(in: rhs)
        guard !lhsValues.isEmpty, !rhsValues.isEmpty else {
            return true
        }

        return lhsValues.contains { lhsValue in
            rhsValues.contains { abs($0 - lhsValue) <= tolerance }
        }
    }

    /// See `VoltageCompatibility.hasRecognizedValue` — same rationale: an unparseable, non-empty
    /// frequency string must not silently fall through `isCompatible`'s "nothing to compare"
    /// default.
    static func hasRecognizedValue(_ string: String) -> Bool {
        !values(in: string).isEmpty
    }

    private static func values(in string: String) -> [Int] {
        string.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}
