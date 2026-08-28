import AppIntents
import Foundation

// MARK: - NextTripRequirementRecommendation

enum NextTripRequirementRecommendation: String, AppEnum, Sendable {
    case noTrip
    case tripDataUnavailable
    case destinationUnavailable
    case homeCountryRequired
    case homeCountryUnavailable
    case adapterRecommended
    case plugAdapterNotExpected

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.next.trip.recommendation.type",
            defaultValue: "Next trip recommendation"
        )
    )

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .noTrip: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.no.trip",
                defaultValue: "No next trip"
            )
        ),
        .tripDataUnavailable: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.trip.unavailable",
                defaultValue: "Trip details unavailable"
            )
        ),
        .destinationUnavailable: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.destination.unavailable",
                defaultValue: "Destination unavailable"
            )
        ),
        .homeCountryRequired: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.home.required",
                defaultValue: "Home country required"
            )
        ),
        .homeCountryUnavailable: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.home.unavailable",
                defaultValue: "Home country information unavailable"
            )
        ),
        .adapterRecommended: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.adapter",
                defaultValue: "Pack a plug adapter"
            )
        ),
        .plugAdapterNotExpected: DisplayRepresentation(
            title: LocalizedStringResource(
                "intent.next.trip.recommendation.adapter.not.expected",
                defaultValue: "Plug adapter not expected"
            )
        )
    ]
}

// MARK: - CountryElectricalProfile

struct CountryElectricalProfile: Equatable, Sendable {
    let code: String
    let name: String
    let voltage: String
    let frequency: String
    let plugTypes: [String]
}

// MARK: - NextTripRequirementsResult

struct NextTripRequirementsResult: Sendable {
    let recommendation: NextTripRequirementRecommendation
    let tripName: String?
    let destinationName: String
    let departureDate: Date?
    let returnDate: Date?
    let voltage: String
    let frequency: String
    let plugTypes: [String]
}
