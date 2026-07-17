import AppIntents
import Foundation
import Repository

/// Opens the detail view for the country the user has set as home.
struct OpenHomeCountryIntent: AppIntent {
    static let title: LocalizedStringResource = "Open home country"
    static let description = IntentDescription("Open your home country’s power information in Voltly.")
    static let supportedModes: IntentModes = .foreground

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        guard let countryCode = defaults?.string(forKey: AppGroup.homeCountryCodeKey),
              !countryCode.isEmpty else {
            return .result(dialog: "Set a home country in Voltly first.")
        }

        defaults?.set(countryCode, forKey: AppGroup.pendingCountryCodeKey)
        return .result(dialog: "Opening your home country in Voltly.")
    }
}
