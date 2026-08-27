import AppIntents
import Foundation
import Repository

/// Opens the detail view for the country the user has set as home.
struct OpenHomeCountryIntent: AppIntent {
    static let title = LocalizedStringResource(
        "intent.open.home.country.title",
        defaultValue: "Open home country"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "intent.open.home.country.description",
            defaultValue: "Open your home country’s power information in Socket Buddy."
        )
    )
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Reuse the same App-Group-with-standard-defaults-fallback logic the rest of the app
        // uses (`UserDefaultsHomeCountryStore`), instead of reading only the App Group suite —
        // a raw `UserDefaults(suiteName:)` read here would report "no home country set" if the
        // App Group container is ever transiently unavailable to this intent's execution
        // context, even though a value exists.
        let countryCode = UserDefaultsHomeCountryStore().homeCountryCode
        guard !countryCode.isEmpty else {
            return .result(
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "intent.open.home.country.missing",
                        defaultValue: "Set a home country in Socket Buddy first."
                    )
                )
            )
        }

        AppNavigationModel.shared.openCountry(code: countryCode)
        return .result(
            dialog: IntentDialog(
                LocalizedStringResource(
                    "intent.open.home.country.opening",
                    defaultValue: "Opening your home country in Socket Buddy."
                )
            )
        )
    }
}
