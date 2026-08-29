import AppIntents

// MARK: - GetCountryPowerIntent

struct GetCountryPowerIntent: AppIntent {
    static let title = LocalizedStringResource(
        "intent.country.power.title",
        defaultValue: "Get country power information"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "intent.country.power.description",
            defaultValue: "Get voltage, frequency, and plug types for a country."
        )
    )
    static let supportedModes: IntentModes = .background
    static let allowedExecutionTargets: IntentExecutionTargets = .main

    @Parameter(
        title: LocalizedStringResource(
            "intent.country.power.parameter",
            defaultValue: "Country"
        )
    )
    var country: CountryEntity

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Get power information for \(\.$country)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<CountryEntity> & ProvidesDialog & ShowsSnippetView {
        let answer = CountryPowerAnswer(country: country)
        return .result(
            value: country,
            dialog: answer.dialog,
            view: CountryPowerSnippet(country: country)
        )
    }
}
