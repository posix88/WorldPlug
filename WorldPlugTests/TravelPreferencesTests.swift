import Foundation
import Testing
@testable import WorldPlug

struct TravelPreferencesTests {
    @Test
    func roundTripsPreferencesWithNextTrip() throws {
        let departureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let returnDate = Date(timeIntervalSince1970: 1_800_864_000)
        let preferences = TravelPreferences(
            savedCountryCodes: ["JP", "IT"],
            nextTrip: NextTrip(
                countryCode: "JP",
                departureDate: departureDate,
                returnDate: returnDate,
                name: "Tokyo"
            ),
            favoriteWidgetCountryCode: "IT"
        )

        let data = try JSONEncoder().encode(preferences)
        let decodedPreferences = try JSONDecoder().decode(TravelPreferences.self, from: data)

        #expect(decodedPreferences == preferences)
    }
}
