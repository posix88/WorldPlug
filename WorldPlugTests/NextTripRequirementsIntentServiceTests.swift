import Foundation
import Testing
@testable import WorldPlug

// MARK: - NextTripRequirementsIntentServiceTests

@Suite("Next trip requirements intent service")
@MainActor
struct NextTripRequirementsIntentServiceTests {
    @Test("reports when no next trip exists")
    func reportsNoTrip() throws {
        let service = NextTripRequirementsIntentService(countryProvider: CountryProviderStub())

        let result = try service.requirements(
            preferences: TravelPreferences(),
            fallbackHomeCountryCode: "",
            now: referenceDate
        )

        #expect(result.recommendation == .noTrip)
    }

    @Test("ignores an expired next trip")
    func ignoresExpiredTrip() throws {
        let service = NextTripRequirementsIntentService(countryProvider: CountryProviderStub())
        let preferences = makePreferences(
            departureDate: referenceDate.addingTimeInterval(-172_800),
            returnDate: referenceDate.addingTimeInterval(-86400)
        )

        let result = try service.requirements(
            preferences: preferences,
            fallbackHomeCountryCode: "US",
            now: referenceDate
        )

        #expect(result.recommendation == .noTrip)
    }

    @Test("rejects malformed trip dates")
    func rejectsMalformedDates() throws {
        let service = NextTripRequirementsIntentService(countryProvider: CountryProviderStub())
        let preferences = makePreferences(
            departureDate: referenceDate.addingTimeInterval(86400),
            returnDate: referenceDate
        )

        let result = try service.requirements(
            preferences: preferences,
            fallbackHomeCountryCode: "US",
            now: referenceDate
        )

        #expect(result.recommendation == .tripDataUnavailable)
    }

    @Test("requires home country before adapter advice")
    func requiresHomeCountry() throws {
        let provider = CountryProviderStub(profiles: ["IT": italy])
        let service = NextTripRequirementsIntentService(countryProvider: provider)

        let result = try service.requirements(
            preferences: makePreferences(homeCountryCode: ""),
            fallbackHomeCountryCode: "",
            now: referenceDate
        )

        #expect(result.recommendation == .homeCountryRequired)
    }

    @Test("recommends adapter when any home plug type does not fit")
    func recommendsAdapter() throws {
        let provider = CountryProviderStub(profiles: [
            "IT": italy,
            "BR": CountryElectricalProfile(
                code: "BR",
                name: "Brazil",
                voltage: "127 V / 220 V",
                frequency: "60 Hz",
                plugTypes: ["C", "N"]
            )
        ])
        let service = NextTripRequirementsIntentService(countryProvider: provider)

        let result = try service.requirements(
            preferences: makePreferences(homeCountryCode: "BR"),
            fallbackHomeCountryCode: "",
            now: referenceDate
        )

        #expect(result.recommendation == .adapterRecommended)
    }

    @Test("reports adapter not expected only when all home plugs fit")
    func reportsAdapterNotExpected() throws {
        let provider = CountryProviderStub(profiles: [
            "IT": italy,
            "DE": CountryElectricalProfile(
                code: "DE",
                name: "Germany",
                voltage: "230 V",
                frequency: "50 Hz",
                plugTypes: ["C", "F"]
            )
        ])
        let service = NextTripRequirementsIntentService(countryProvider: provider)

        let result = try service.requirements(
            preferences: makePreferences(homeCountryCode: "DE"),
            fallbackHomeCountryCode: "",
            now: referenceDate
        )

        #expect(result.recommendation == .plugAdapterNotExpected)
    }

    @Test("Italian answer distinguishes adapter from device safety")
    func italianAnswerIsConservative() {
        let result = NextTripRequirementsResult(
            recommendation: .plugAdapterNotExpected,
            tripName: "Roma",
            destinationName: "Italia",
            departureDate: referenceDate,
            returnDate: referenceDate.addingTimeInterval(604_800),
            voltage: "230 V",
            frequency: "50 Hz",
            plugTypes: ["C", "F", "L"]
        )

        let answer = NextTripRequirementsAnswer(
            result: result,
            locale: Locale(identifier: "it")
        )

        #expect(answer.text.contains("non dovrebbe servire"))
        #expect(answer.text.contains("Controlla comunque l’etichetta"))
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private var italy: CountryElectricalProfile {
        CountryElectricalProfile(
            code: "IT",
            name: "Italy",
            voltage: "230 V",
            frequency: "50 Hz",
            plugTypes: ["C", "F", "L"]
        )
    }

    private func makePreferences(
        homeCountryCode: String = "US",
        departureDate: Date? = nil,
        returnDate: Date? = nil
    ) -> TravelPreferences {
        let departure = departureDate ?? referenceDate.addingTimeInterval(86400)
        let returnDate = returnDate ?? departure.addingTimeInterval(604_800)
        return TravelPreferences(
            homeCountryCode: homeCountryCode,
            nextTrip: NextTrip(
                countryCode: "IT",
                departureDate: departure,
                returnDate: returnDate,
                name: "Rome"
            )
        )
    }
}

// MARK: - CountryProviderStub

@MainActor
private struct CountryProviderStub: NextTripCountryProviding {
    var profiles: [String: CountryElectricalProfile] = [:]

    func profile(countryCode: String, locale: Locale) -> CountryElectricalProfile? {
        profiles[countryCode.uppercased()]
    }
}
