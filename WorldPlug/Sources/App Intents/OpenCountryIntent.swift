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
            defaultValue: "Open a country’s power information in Socket Buddy."
        )
    )

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
            intent: GetNextTripRequirementsIntent(),
            phrases: [
                "What do I need for my next trip with \(.applicationName)",
                "Get my next trip requirements with \(.applicationName)",
                "Prepare me for my next trip with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "intent.next.trip.title",
                defaultValue: "Get next trip requirements"
            ),
            systemImageName: "suitcase.rolling.fill"
        )
        AppShortcut(
            intent: CheckDeviceCompatibilityIntent(),
            phrases: [
                "Can I use a device in \(\.$destination) with \(.applicationName)",
                "Check device compatibility for \(\.$destination) with \(.applicationName)",
                "Is my device safe in \(\.$destination) with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "intent.device.compatibility.title",
                defaultValue: "Check a device"
            ),
            systemImageName: "checkmark.shield.fill"
        )
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
        AppShortcut(
            intent: GetCountryPowerIntent(),
            phrases: [
                "Get power information for \(\.$country) with \(.applicationName)",
                "What voltage does \(\.$country) use in \(.applicationName)",
                "What plug types does \(\.$country) use in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "intent.country.power.title",
                defaultValue: "Get country power information"
            ),
            systemImageName: "powerplug.fill"
        )
    }
}
