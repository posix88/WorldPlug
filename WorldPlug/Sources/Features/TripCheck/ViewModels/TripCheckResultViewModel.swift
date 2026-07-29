import Analytics
import Observation
import Repository

// MARK: - TripCheckResultViewModel

@Observable
@MainActor
final class TripCheckResultViewModel {
    private let analyticsTracker: any AnalyticsTracker
    private let requestsReviewAfterAppearance: Bool

    let tripCheck: TripCheck
    let destination: Country?
    let assessments: [DeviceSafetyAssessment]

    init(
        tripCheck: TripCheck,
        countries: [Country],
        homeCountry: Country?,
        requestsReviewAfterAppearance: Bool,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.tripCheck = tripCheck
        self.destination = countries.first(where: { $0.code == tripCheck.countryCode })
        self.requestsReviewAfterAppearance = requestsReviewAfterAppearance
        self.analyticsTracker = analyticsTracker
        self.assessments = destination.map {
            TripSafetyChecker.assessments(
                devices: tripCheck.devices,
                homeCountry: homeCountry,
                destination: $0
            )
        } ?? []
    }

    func screenAppeared(requestReview: () -> Void) {
        analyticsTracker.track(.deviceSafetyResultViewed)
        if requestsReviewAfterAppearance {
            AppReviewPrompt.requestAfterSuccessfulAction(using: requestReview)
        }
    }
}
