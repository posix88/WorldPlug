import AppIntents

// MARK: - OpenCountryIntent

struct OpenCountryIntent: OpenIntent, TargetContentProvidingIntent {
    static let title = LocalizedStringResource(
        "intent.open.country.title",
        defaultValue: "Open country"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "intent.open.country.description",
            defaultValue: "Open a country’s power information in Voltly."
        )
    )

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets {
        .main
    }

    @Parameter(
        title: LocalizedStringResource(
            "intent.open.country.parameter",
            defaultValue: "Country"
        )
    )
    var target: CountryEntity

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }
}

// MARK: - VoltlyAppShortcuts

struct VoltlyAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCountryIntent(),
            phrases: [
                "Open a country in \(.applicationName)",
                "Show country power information in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "intent.open.country.title",
                defaultValue: "Open country"
            ),
            systemImageName: "globe.europe.africa.fill"
        )
        AppShortcut(
            intent: OpenHomeCountryIntent(),
            phrases: [
                "Open my home country in \(.applicationName)",
                "Show my home country in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "intent.open.home.country.title",
                defaultValue: "Open home country"
            ),
            systemImageName: "house.fill"
        )
    }
}
