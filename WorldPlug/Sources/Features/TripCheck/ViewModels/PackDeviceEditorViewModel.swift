import Foundation
import Observation

// MARK: - PackDeviceEditorViewModel

@Observable
@MainActor
final class PackDeviceEditorViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding

    var name = ""
    var symbolName = DeviceIconOption.all[0].symbolName
    var voltage = DeviceElectricalOption.voltages[0]
    var frequency = DeviceElectricalOption.frequencies[0]
    var isIconPickerPresented = false
    var shouldPresentIconPaywall = false
    var isPremiumPaywallPresented = false

    init(premiumEntitlement: any PremiumEntitlementProviding) {
        self.premiumEntitlement = premiumEntitlement
    }

    var isPremium: Bool { premiumEntitlement.isPremium }
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
            name: normalizedName,
            symbolName: symbolName,
            voltage: voltage,
            frequency: frequency
        )
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
