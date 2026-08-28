import AppIntents
import Foundation

// MARK: - NextTripRequirementsAnswer

struct NextTripRequirementsAnswer: Sendable {
    let text: String

    init(result: NextTripRequirementsResult, locale: Locale = .current) {
        self.text = switch result.recommendation {
        case .noTrip:
            Self.localizedString("intent.next.trip.dialog.no.trip", locale: locale)

        case .tripDataUnavailable:
            Self.formatted(
                "intent.next.trip.dialog.trip.unavailable",
                locale: locale,
                result.destinationName
            )

        case .destinationUnavailable:
            Self.formatted(
                "intent.next.trip.dialog.destination.unavailable",
                locale: locale,
                result.destinationName
            )

        case .homeCountryRequired:
            Self.tripDetails(result: result, locale: locale)
                + " "
                + Self.localizedString("intent.next.trip.dialog.home.required", locale: locale)

        case .homeCountryUnavailable:
            Self.tripDetails(result: result, locale: locale)
                + " "
                + Self.localizedString("intent.next.trip.dialog.home.unavailable", locale: locale)

        case .adapterRecommended:
            Self.tripDetails(result: result, locale: locale)
                + " "
                + Self.localizedString("intent.next.trip.dialog.adapter", locale: locale)

        case .plugAdapterNotExpected:
            Self.tripDetails(result: result, locale: locale)
                + " "
                + Self.localizedString("intent.next.trip.dialog.adapter.not.expected", locale: locale)
        }
    }

    var dialog: IntentDialog {
        IntentDialog(stringLiteral: text)
    }

    private static func tripDetails(result: NextTripRequirementsResult, locale: Locale) -> String {
        let plugTypes = result.plugTypes.formatted(.list(type: .and).locale(locale))
        let dates = dateRange(result: result, locale: locale)
        return formatted(
            "intent.next.trip.dialog.details",
            locale: locale,
            result.destinationName,
            dates,
            result.voltage,
            result.frequency,
            plugTypes
        )
    }

    private static func dateRange(result: NextTripRequirementsResult, locale: Locale) -> String {
        guard let departureDate = result.departureDate, let returnDate = result.returnDate else {
            return ""
        }

        let style = Date.FormatStyle(date: .long, time: .omitted).locale(locale)
        return formatted(
            "intent.next.trip.dialog.date.range",
            locale: locale,
            departureDate.formatted(style),
            returnDate.formatted(style)
        )
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
