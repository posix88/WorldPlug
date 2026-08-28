import AppIntents
import Foundation

// MARK: - DeviceCompatibilityAnswer

struct DeviceCompatibilityAnswer: Sendable {
    let text: String

    init(result: DeviceCompatibilityResult, locale: Locale = .current) {
        self.text = switch result.recommendation {
        case .ready:
            Self.formatted(
                "intent.device.compatibility.dialog.ready",
                locale: locale,
                result.deviceName,
                result.destinationName,
                result.destinationVoltage,
                result.destinationFrequency
            )

        case .adapterNeeded:
            Self.formatted(
                "intent.device.compatibility.dialog.adapter",
                locale: locale,
                result.deviceName,
                result.destinationName,
                result.destinationVoltage,
                result.destinationFrequency
            )

        case .homeCountryRequired:
            Self.formatted(
                "intent.device.compatibility.dialog.home.country",
                locale: locale,
                result.deviceName,
                result.destinationName
            )

        case .checkLabel:
            Self.formatted(
                "intent.device.compatibility.dialog.check.label",
                locale: locale,
                result.deviceName,
                result.destinationName,
                result.explanation
            )

        case .frequencyRequired:
            Self.formatted(
                "intent.device.compatibility.dialog.frequency.required",
                locale: locale,
                result.deviceName,
                result.destinationName,
                result.destinationFrequency
            )

        case .unsafe:
            Self.formatted(
                "intent.device.compatibility.dialog.unsafe",
                locale: locale,
                result.deviceName,
                result.destinationName,
                result.destinationVoltage,
                result.destinationFrequency,
                result.explanation
            )

        case .destinationUnavailable:
            Self.formatted(
                "intent.device.compatibility.dialog.destination.unavailable",
                locale: locale,
                result.destinationName
            )
        }
    }

    var dialog: IntentDialog {
        IntentDialog(stringLiteral: text)
    }

    private static func formatted(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(
            format: localizedString(key, locale: locale),
            locale: locale,
            arguments: arguments
        )
    }

    private static func localizedString(_ key: String, locale: Locale) -> String {
        let languageCode = locale.language.languageCode?.identifier
        let localizedBundle = languageCode
            .flatMap { Bundle.main.url(forResource: $0, withExtension: "lproj") }
            .flatMap { Bundle(url: $0) }
        return String(
            localized: String.LocalizationValue(key),
            bundle: localizedBundle ?? .main,
            locale: locale
        )
    }
}
