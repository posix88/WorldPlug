import Analytics
import Foundation
import Observation
import Repository

// MARK: - TripCheckRowModel

struct TripCheckRowModel: Identifiable {
    let trip: Trip
    let country: Country
    let safetySummary: String

    var id: UUID { trip.id }
}

// MARK: - TripCheckViewModel

@Observable
@MainActor
final class TripCheckViewModel {
    private let travelPreferencesStore: any TravelPreferencesStoring
    private let homeCountryViewModel: any HomeCountryViewModelType
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let analyticsTracker: any AnalyticsTracker

    private(set) var countries: [Country] = []
    var isEditorPresented = false
    var isPremiumPaywallPresented = false
    var selectedTrip: Trip?
    var requestsReviewForSelectedTrip = false

    init(
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.travelPreferencesStore = travelPreferencesStore
        self.homeCountryViewModel = homeCountryViewModel
        self.premiumEntitlement = premiumEntitlement
        self.analyticsTracker = analyticsTracker
    }

    var trips: [Trip] {
        travelPreferencesStore.preferences.trips.sorted { $0.departureDate < $1.departureDate }
    }

    var rows: [TripCheckRowModel] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return trips.compactMap { trip in
            guard let country = countriesByCode[trip.countryCode] else {
                return nil
            }

            let assessments = TripSafetyChecker.assessments(
                devices: trip.devices,
                homeCountry: homeCountryViewModel.homeCountry,
                destination: country
            )
            return TripCheckRowModel(
                trip: trip,
                country: country,
                safetySummary: Self.safetySummary(assessments)
            )
        }
    }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.trips)
    }

    func beginTripCheck() {
        guard premiumEntitlement.isPremium || trips.count(where: { !$0.isPast() }) < 1 else {
            analyticsTracker.track(.tripLimitReached)
            isPremiumPaywallPresented = true
            return
        }

        analyticsTracker.track(.tripCheckStarted)
        isEditorPresented = true
    }

    func select(_ trip: Trip) {
        requestsReviewForSelectedTrip = false
        selectedTrip = trip
    }

    func save(_ trip: Trip) {
        travelPreferencesStore.saveTrip(trip)
        analyticsTracker.track(.tripCheckCompleted)
        requestsReviewForSelectedTrip = true
        selectedTrip = trip
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            travelPreferencesStore.removeTrip(id: trips[index].id)
        }
    }

    private static func safetySummary(_ assessments: [DeviceSafetyAssessment]) -> String {
        DeviceSafetyStatus.allCases.compactMap { status in
            let count = assessments.count(where: { $0.status == status })
            return count == 0 ? nil : "\(count) \(status.title)"
        }
        .joined(separator: " · ")
    }
}
