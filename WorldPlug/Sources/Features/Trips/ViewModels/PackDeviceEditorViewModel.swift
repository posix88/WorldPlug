import Foundation
import Observation
import Repository

// MARK: - PackDeviceEditorViewModel

@Observable
@MainActor
final class PackDeviceEditorViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding

    /// `nil` when adding, set when editing — `makeDevice()` reuses it so an edit replaces the
    /// device instead of appending a second one.
    private let editingDeviceID: UUID?

    var name: String
    var symbolName: String
    var voltage: String
    var frequency: String
    var isIconPickerPresented = false
    var shouldPresentIconPaywall = false
    var isPremiumPaywallPresented = false

    init(device: PackDevice? = nil, premiumEntitlement: any PremiumEntitlementProviding) {
        self.editingDeviceID = device?.id
        self.name = device?.name ?? ""
        self.symbolName = device?.symbolName ?? DeviceIconOption.all[0].symbolName
        // A stored value has to be mapped back onto the wheel's options or the picker opens with
        // nothing selected. Exact match first, then `matching*` (which compares the numbers, so
        // "100-240V" with a hyphen resolves to the "100–240V" en-dash option the wheel offers),
        // then the first option.
        self.voltage = Self.option(
            for: device?.voltage,
            in: DeviceElectricalOption.voltages,
            matching: DeviceElectricalOption.matchingVoltage
        )
        self.frequency = Self.option(
            for: device?.frequency,
            in: DeviceElectricalOption.frequencies,
            matching: DeviceElectricalOption.matchingFrequency
        )
        self.premiumEntitlement = premiumEntitlement
    }

    var isPremium: Bool { premiumEntitlement.isPremium }
    var isExisting: Bool { editingDeviceID != nil }
    var canSave: Bool { !normalizedName.isEmpty }

    func scanLabel() -> Bool {
        guard isPremium else {
            isPremiumPaywallPresented = true
            return false
        }

        return true
    }

    func applyScannedValues(_ values: DeviceLabelValues) {
        if let parsedVoltage = DeviceElectricalOption.matchingVoltage(values.voltage) {
            voltage = parsedVoltage
        }
        if let parsedFrequency = DeviceElectricalOption.matchingFrequency(values.frequency) {
            frequency = parsedFrequency
        }
    }

    func requestPremiumIcon() {
        shouldPresentIconPaywall = true
        isIconPickerPresented = false
    }

    func iconPickerDismissed() {
        guard shouldPresentIconPaywall else {
            return
        }

        shouldPresentIconPaywall = false
        isPremiumPaywallPresented = true
    }

    func makeDevice() -> PackDevice {
        PackDevice(
            id: editingDeviceID ?? UUID(),
            name: normalizedName,
            symbolName: symbolName,
            voltage: voltage,
            frequency: frequency
        )
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func option(
        for value: String?,
        in options: [String],
        matching: (String) -> String?
    ) -> String {
        guard let value, !value.isEmpty else {
            return options[0]
        }

        if options.contains(value) {
            return value
        }

        return matching(value) ?? options[0]
    }
}
