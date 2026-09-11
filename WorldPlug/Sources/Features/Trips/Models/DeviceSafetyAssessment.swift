import Foundation
import Repository

// MARK: - DeviceSafetyStatus

enum DeviceSafetyStatus: CaseIterable {
    case ready
    case adapterNeeded
    case homeCountryRequired
    case checkLabel
    case unsafe

    /// `LocalizedStringResource`, not `String`: a verdict is produced in the model layer and
    /// displayed later, so resolving it here would freeze whatever language was active at
    /// assessment time. The resource resolves at the display site instead.
    var title: LocalizedStringResource {
        switch self {
        case .ready: LocalizationKeys.tripCheckStatusReady
        case .adapterNeeded: LocalizationKeys.tripCheckStatusAdapter
        case .homeCountryRequired: LocalizationKeys.tripCheckStatusHomeCountry
        case .checkLabel: LocalizationKeys.tripCheckStatusCheckLabel
        case .unsafe: LocalizationKeys.tripCheckStatusUnsafe
        }
    }

    var symbolName: String {
        switch self {
        case .ready: "checkmark.seal.fill"
        case .adapterNeeded: "powerplug.fill"
        case .homeCountryRequired: "house.fill"
        case .checkLabel: "exclamationmark.triangle.fill"
        case .unsafe: "xmark.octagon.fill"
        }
    }
}

// MARK: - DeviceSafetyAssessment

struct DeviceSafetyAssessment: Identifiable {
    let device: PackDevice
    let status: DeviceSafetyStatus
    /// Stays a `String` while `status.title` became a `LocalizedStringResource`, because two of
    /// the five messages interpolate a runtime value (the destination's voltage or frequency) and
    /// this project's catalog uses opaque keys whose *values* hold the `%@`. A resource cannot
    /// carry that combination — see `LocalizedStringResource.string(_:)`. In practice nothing is
    /// lost: assessments are built inside a view body and rendered in the same pass. Making this
    /// a resource too would mean either moving the placeholders into the keys (a second catalog
    /// convention) or turning the verdict into an enum with associated values — worth doing, but
    /// not as a drive-by on the one type with real electrical-safety consequences.
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
                message: String(localized: LocalizationKeys.tripCheckMessageMissingVoltage)
            )
        }
        guard VoltageCompatibility.deviceInputSupports(trimmedVoltage, destinationSupply: destination.voltage) else {
            return DeviceSafetyAssessment(
                device: device,
                status: .unsafe,
                message: LocalizationKeys.tripCheckMessageUnsafe.string(destination.voltage)
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
                    message: LocalizationKeys.tripCheckMessageFrequency.string(destination.frequency)
                )
            }
        }

        guard let homeCountry else {
            return DeviceSafetyAssessment(
                device: device,
                status: .homeCountryRequired,
                message: String(localized: LocalizationKeys.tripCheckMessageSetHome)
            )
        }

        let homePlugTypes = Set(homeCountry.plugs.map(\.id))
        let destinationPlugTypes = Set(destination.plugs.map(\.id))
        let allHomePlugsMatch = homePlugTypes.isSubset(of: destinationPlugTypes)
        return DeviceSafetyAssessment(
            device: device,
            status: allHomePlugsMatch ? .ready : .adapterNeeded,
            message: allHomePlugsMatch
                ? String(localized: LocalizationKeys.tripCheckMessageReady)
                : String(localized: LocalizationKeys.tripCheckMessageAdapter)
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

        return rhsValues.allSatisfy { rhsValue in
            lhsValues.contains { abs($0 - rhsValue) <= tolerance }
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
