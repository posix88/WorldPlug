import Analytics
import Foundation
import Observation
import Repository

// MARK: - TripCheckRowModel

struct TripCheckRowModel: Identifiable {
    let tripCheck: TripCheck
    let country: Country
    let safetySummary: String

    var id: UUID { tripCheck.id }
}

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
    var selectedTripCheck: TripCheck?
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

    var tripChecks: [TripCheck] {
        travelPreferencesStore.preferences.tripChecks.sorted { $0.departureDate < $1.departureDate }
    }

    var rows: [TripCheckRowModel] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return tripChecks.compactMap { tripCheck in
            guard let country = countriesByCode[tripCheck.countryCode] else {
                return nil
            }
            let assessments = TripSafetyChecker.assessments(
                devices: tripCheck.devices,
                homeCountry: homeCountryViewModel.homeCountry,
                destination: country
            )
            return TripCheckRowModel(
                tripCheck: tripCheck,
                country: country,
                safetySummary: Self.safetySummary(assessments)
            )
        }
    }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.nextTrip)
    }

    func beginTripCheck() {
        guard premiumEntitlement.isPremium || tripChecks.count < 1 else {
            analyticsTracker.track(.tripCheckLimitReached)
            isPremiumPaywallPresented = true
            return
        }
        analyticsTracker.track(.tripCheckStarted)
        isEditorPresented = true
    }

    func select(_ tripCheck: TripCheck) {
        requestsReviewForSelectedTrip = false
        selectedTripCheck = tripCheck
    }

    func save(_ tripCheck: TripCheck) {
        travelPreferencesStore.saveTripCheck(tripCheck)
        analyticsTracker.track(.tripCheckCompleted)
        requestsReviewForSelectedTrip = true
        selectedTripCheck = tripCheck
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            travelPreferencesStore.removeTripCheck(id: tripChecks[index].id)
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
