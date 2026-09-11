import Analytics
import Foundation
import Observation
import Repository

// MARK: - TripRowModel

struct TripRowModel: Identifiable {
    let trip: Trip
    let country: Country
    let safetySummary: String
    /// The one trip the widgets and Siri talk about. Badged in the list so the widget's behaviour
    /// is visible in the app instead of being invisible magic.
    let isNext: Bool

    var id: UUID { trip.id }
}

// MARK: - TripsViewModel

@Observable
@MainActor
final class TripsViewModel {
    /// How many trips a non-premium user can have. Past trips don't count — an old trip shouldn't
    /// lock someone out of planning a new one.
    static let freeTripLimit = 1

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

    var trips: [Trip] { travelPreferencesStore.trips }

    /// Soonest first — the trip you're about to take, or are on, belongs at the top.
    var upcomingRows: [TripRowModel] {
        rows(for: trips.filter { !$0.isPast() }.sorted { $0.departureDate < $1.departureDate })
    }

    /// Most recent first — a trip you just got back from is the one you'd reopen.
    var pastRows: [TripRowModel] {
        rows(for: trips.filter { $0.isPast() }.sorted { $0.departureDate > $1.departureDate })
    }

    var hasTrips: Bool { !trips.isEmpty }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func screenAppeared() {
        analyticsTracker.screen(.trips)
    }

    func beginTrip() {
        let activeTripCount = trips.count(where: { !$0.isPast() })
        guard premiumEntitlement.isPremium || activeTripCount < Self.freeTripLimit else {
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

    /// A freshly created trip has no devices yet, so it opens straight into its detail screen —
    /// that's where devices get added.
    func save(_ trip: Trip) {
        travelPreferencesStore.saveTrip(trip)
        requestsReviewForSelectedTrip = false
        selectedTrip = trip
    }

    func delete(_ trip: Trip) {
        travelPreferencesStore.removeTrip(id: trip.id)
    }

    /// Deletes by identity rather than by index into a flat array — the list is split into
    /// Upcoming and Past sections, so a row's offset within its own section says nothing about
    /// its position in `trips`.
    func deleteUpcoming(at offsets: IndexSet) {
        delete(upcomingRows, at: offsets)
    }

    func deletePast(at offsets: IndexSet) {
        delete(pastRows, at: offsets)
    }

    private func delete(_ rows: [TripRowModel], at offsets: IndexSet) {
        for id in offsets.compactMap({ rows.indices.contains($0) ? rows[$0].trip.id : nil }) {
            travelPreferencesStore.removeTrip(id: id)
        }
    }

    private func rows(for trips: [Trip]) -> [TripRowModel] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        let nextTripID = travelPreferencesStore.currentTrip?.id

        return trips.compactMap { trip in
            guard let country = countriesByCode[trip.countryCode] else {
                return nil
            }

            let assessments = TripSafetyChecker.assessments(
                devices: trip.devices,
                homeCountry: homeCountryViewModel.homeCountry,
                destination: country
            )
            return TripRowModel(
                trip: trip,
                country: country,
                safetySummary: Self.safetySummary(assessments),
                isNext: trip.id == nextTripID
            )
        }
    }

    /// "2 Ready · 1 Adapter needed".
    ///
    /// Resolved to a `String` here rather than deferred, because it is a composed tally of
    /// per-status counts rather than one catalog entry. It is only ever built from inside a view
    /// body (`upcomingRows`/`pastRows` are read there), so resolution still happens at display
    /// time. `count.formatted()` keeps the numerals locale-correct — plain interpolation of an
    /// `Int` would emit ASCII digits.
    private static func safetySummary(_ assessments: [DeviceSafetyAssessment]) -> String {
        guard !assessments.isEmpty else {
            return String(localized: LocalizationKeys.tripsRowNoDevices)
        }

        return DeviceSafetyStatus.allCases.compactMap { status in
            let count = assessments.count(where: { $0.status == status })
            guard count > 0 else {
                return nil
            }

            return "\(count.formatted()) \(String(localized: status.title))"
        }
        .joined(separator: " · ")
    }
}
