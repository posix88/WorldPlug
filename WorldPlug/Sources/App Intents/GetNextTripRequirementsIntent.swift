import AppIntents
import Repository

// MARK: - GetNextTripRequirementsIntent

struct GetNextTripRequirementsIntent: AppIntent {
    static let title = LocalizedStringResource(
        "intent.next.trip.title",
        defaultValue: "Get next trip requirements"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "intent.next.trip.description",
            defaultValue: "Get plug, voltage, and frequency requirements for your next trip."
        )
    )
    static let supportedModes: IntentModes = .background
    static let allowedExecutionTargets: IntentExecutionTargets = .main

    static var parameterSummary: some ParameterSummary {
        Summary("Get my next trip requirements")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<NextTripRequirementRecommendation> & ProvidesDialog &
        ShowsSnippetView {
        let preferences = ICloudTravelPreferencesStore().preferences
        let countryProvider = SwiftDataNextTripCountryRepository(
            modelContext: Repository.sharedModelContainer.mainContext
        )
        let service = NextTripRequirementsIntentService(countryProvider: countryProvider)
        let result = try service.requirements(
            preferences: preferences,
            fallbackHomeCountryCode: UserDefaultsHomeCountryStore().homeCountryCode
        )
        let answer = NextTripRequirementsAnswer(result: result)
        return .result(
            value: result.recommendation,
            dialog: answer.dialog,
            view: NextTripRequirementsSnippet(result: result)
        )
    }
}
