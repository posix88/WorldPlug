import Foundation

// MARK: - DeviceIconOption

struct DeviceIconOption: Identifiable {
    let symbolName: String
    /// `LocalizedStringResource`: these options are `static let` constants built once at
    /// load time, so a `String` here would bake in whatever locale was active then and keep
    /// it for the life of the process.
    let accessibilityLabel: LocalizedStringResource
    let requiresPremium: Bool

    var id: String { symbolName }

    static let all = [
        DeviceIconOption(
            symbolName: "powerplug.fill",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceIconPlug,
            requiresPremium: false
        ),
        DeviceIconOption(
            symbolName: "iphone",
            accessibilityLabel: LocalizationKeys.tripCheckDevicePhone,
            requiresPremium: false
        ),
        DeviceIconOption(
            symbolName: "laptopcomputer",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceLaptop,
            requiresPremium: false
        ),
        DeviceIconOption(
            symbolName: "camera",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceCamera,
            requiresPremium: false
        ),
        DeviceIconOption(
            symbolName: "bolt.fill",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceIconOther,
            requiresPremium: false
        ),
        DeviceIconOption(
            symbolName: "headphones",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceHeadphones,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "speaker.wave.2.fill",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceSpeaker,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "gamecontroller.fill",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceGameController,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "applewatch",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceSmartwatch,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "wind",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceHairDryer,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "sparkles",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceHairStyler,
            requiresPremium: true
        ),
        DeviceIconOption(
            symbolName: "cross.case.fill",
            accessibilityLabel: LocalizationKeys.tripCheckDeviceCPAP,
            requiresPremium: true
        )
    ]
}

// MARK: - DeviceElectricalOption

enum DeviceElectricalOption {
    static let voltages = ["100–120V", "100–127V", "100–240V", "110–240V", "220–240V", "230V"]
    static let frequencies = ["50Hz", "60Hz", "50/60Hz"]

    static func matchingVoltage(_ value: String) -> String? {
        let values = numbers(in: value)
        return voltages.first { numbers(in: $0) == values }
    }

    static func matchingFrequency(_ value: String) -> String? {
        let values = numbers(in: value)
        return frequencies.first { numbers(in: $0) == values }
    }

    private static func numbers(in value: String) -> [Int] {
        value.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}
