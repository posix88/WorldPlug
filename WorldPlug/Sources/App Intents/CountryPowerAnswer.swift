import AppIntents
import Foundation

// MARK: - CountryPowerAnswer

struct CountryPowerAnswer: Sendable {
    let text: String

    init(country: CountryEntity, locale: Locale = .current) {
        let plugTypes = country.plugTypes.isEmpty
            ? Self.localizedString("intent.country.power.plugs.unavailable", locale: locale)
            : country.plugTypes.formatted(.list(type: .and).locale(locale))
        let format = Self.localizedString("intent.country.power.dialog.full", locale: locale)

        self.text = String(
            format: format,
            locale: locale,
            country.name,
            country.voltage,
            country.frequency,
            plugTypes
        )
    }

    var dialog: IntentDialog {
        IntentDialog(stringLiteral: text)
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
