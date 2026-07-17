import AppIntents
import Foundation
import Repository

struct OpenCountryIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open country"
    static let description = IntentDescription("Open a country’s power information in Voltly.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Country")
    var target: CountryEntity

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: AppGroup.identifier)?.set(
            target.id,
            forKey: AppGroup.pendingCountryCodeKey
        )

        return .result()
    }
}

struct VoltlyAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCountryIntent(),
            phrases: [
                "Open a country in \(.applicationName)",
                "Show country power information in \(.applicationName)"
            ],
            shortTitle: "Open country",
            systemImageName: "globe.europe.africa.fill"
        )
        AppShortcut(
            intent: OpenHomeCountryIntent(),
            phrases: [
                "Open my home country in \(.applicationName)",
                "Show my home country in \(.applicationName)"
            ],
            shortTitle: "Open home country",
            systemImageName: "house.fill"
        )
    }
}
