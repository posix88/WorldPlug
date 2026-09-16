import Foundation
import Repository
import Testing
@testable import WorldPlug

struct TravelPreferencesTests {
    @Test
    func roundTripsPreferencesWithATrip() throws {
        let departureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let returnDate = Date(timeIntervalSince1970: 1_800_864_000)
        let preferences = TravelPreferences(
            homeCountryCode: "GB",
            savedCountryCodes: ["JP", "IT"],
            favoriteWidgetCountryCode: "IT",
            trips: [
                Trip(
                    countryCode: "JP",
                    departureDate: departureDate,
                    returnDate: returnDate,
                    name: "Tokyo"
                )
            ]
        )

        let data = try JSONEncoder().encode(preferences)
        let decodedPreferences = try JSONDecoder().decode(TravelPreferences.self, from: data)

        #expect(decodedPreferences == preferences)
    }

    // MARK: - currentTrip

    @Test("no trips means no current trip")
    func currentTripIsNilWithoutTrips() {
        #expect(TravelPreferences().currentTrip(now: .now) == nil)
    }

    @Test("the soonest upcoming departure wins")
    func currentTripPicksSoonestUpcoming() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let soon = Self.trip(code: "JP", departureIn: 3, days: 7, from: now)
        let later = Self.trip(code: "IT", departureIn: 40, days: 5, from: now)
        let preferences = TravelPreferences(trips: [later, soon])

        #expect(preferences.currentTrip(now: now)?.countryCode == "JP")
    }

    @Test("an in-progress trip beats a sooner-departing future one")
    func currentTripPrefersOngoing() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let ongoing = Self.trip(code: "US", departureIn: -2, days: 9, from: now)
        let upcoming = Self.trip(code: "JP", departureIn: 1, days: 7, from: now)
        let preferences = TravelPreferences(trips: [upcoming, ongoing])

        #expect(preferences.currentTrip(now: now)?.countryCode == "US")
    }

    @Test("a trip is ongoing for the whole of its departure and return days")
    func currentTripCoversBoundaryDays() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let startingToday = Self.trip(code: "JP", departureIn: 0, days: 0, from: now)
        let preferences = TravelPreferences(trips: [startingToday])

        // Same calendar day as both the departure and the return date, several hours later.
        let laterToday = now.addingTimeInterval(6 * 60 * 60)
        #expect(preferences.currentTrip(now: laterToday)?.countryCode == "JP")
    }

    @Test("trips that have already ended are never current")
    func currentTripIgnoresPastTrips() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let past = Self.trip(code: "US", departureIn: -30, days: 9, from: now)
        let preferences = TravelPreferences(trips: [past])

        #expect(preferences.currentTrip(now: now) == nil)
        #expect(past.isPast(now: now))
    }

    private static func trip(code: String, departureIn days: Int, days duration: Int, from now: Date) -> Trip {
        let day: TimeInterval = 24 * 60 * 60
        let departureDate = now.addingTimeInterval(Double(days) * day)
        return Trip(
            countryCode: code,
            departureDate: departureDate,
            returnDate: departureDate.addingTimeInterval(Double(duration) * day)
        )
    }
}
