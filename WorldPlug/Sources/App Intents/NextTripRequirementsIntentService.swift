import Foundation
import Repository
import SwiftData

// MARK: - NextTripCountryProviding

@MainActor
protocol NextTripCountryProviding {
    func profile(countryCode: String, locale: Locale) throws -> CountryElectricalProfile?
}

// MARK: - SwiftDataNextTripCountryRepository

@MainActor
struct SwiftDataNextTripCountryRepository: NextTripCountryProviding {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func profile(countryCode: String, locale: Locale) throws -> CountryElectricalProfile? {
        let normalizedCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedCode.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<Country>(
            predicate: #Predicate { $0.code == normalizedCode }
        )
        descriptor.fetchLimit = 1
        guard let country = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return CountryElectricalProfile(
            code: country.code,
            name: country.localizedName(in: locale),
            voltage: country.voltage,
            frequency: country.frequency,
            plugTypes: country.sortedPlugs.map(\.id)
        )
    }
}

// MARK: - NextTripRequirementsIntentService

@MainActor
struct NextTripRequirementsIntentService {
    private let countryProvider: any NextTripCountryProviding

    init(countryProvider: any NextTripCountryProviding) {
        self.countryProvider = countryProvider
    }

    func requirements(
        preferences: TravelPreferences,
        fallbackHomeCountryCode: String,
        locale: Locale = .current,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> NextTripRequirementsResult {
        guard let trip = preferences.nextTrip else {
            return emptyResult(recommendation: .noTrip)
        }

        let departureDay = calendar.startOfDay(for: trip.departureDate)
        let returnDay = calendar.startOfDay(for: trip.returnDate)
        guard returnDay >= departureDay else {
            return result(for: trip, recommendation: .tripDataUnavailable)
        }
        guard returnDay >= calendar.startOfDay(for: now) else {
            return emptyResult(recommendation: .noTrip)
        }
        guard let destination = try countryProvider.profile(countryCode: trip.countryCode, locale: locale),
              destination.hasCompleteElectricalData else {
            return result(for: trip, recommendation: .destinationUnavailable)
        }

        let preferredHomeCode = preferences.homeCountryCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeCountryCode = preferredHomeCode.isEmpty ? fallbackHomeCountryCode : preferredHomeCode
        guard !homeCountryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return result(for: trip, destination: destination, recommendation: .homeCountryRequired)
        }
        guard let homeCountry = try countryProvider.profile(countryCode: homeCountryCode, locale: locale),
              !homeCountry.plugTypes.isEmpty else {
            return result(for: trip, destination: destination, recommendation: .homeCountryUnavailable)
        }

        let recommendation = NextTripRequirementsEvaluator.recommendation(
            homePlugTypes: homeCountry.plugTypes,
            destinationPlugTypes: destination.plugTypes
        )
        return result(for: trip, destination: destination, recommendation: recommendation)
    }

    private func emptyResult(recommendation: NextTripRequirementRecommendation) -> NextTripRequirementsResult {
        NextTripRequirementsResult(
            recommendation: recommendation,
            tripName: nil,
            destinationName: "",
            departureDate: nil,
            returnDate: nil,
            voltage: "",
            frequency: "",
            plugTypes: []
        )
    }

    private func result(
        for trip: NextTrip,
        destination: CountryElectricalProfile? = nil,
        recommendation: NextTripRequirementRecommendation
    ) -> NextTripRequirementsResult {
        NextTripRequirementsResult(
            recommendation: recommendation,
            tripName: trip.name,
            destinationName: destination?.name ?? trip.countryCode,
            departureDate: trip.departureDate,
            returnDate: trip.returnDate,
            voltage: destination?.voltage ?? "",
            frequency: destination?.frequency ?? "",
            plugTypes: destination?.plugTypes ?? []
        )
    }
}

// MARK: - NextTripRequirementsEvaluator

enum NextTripRequirementsEvaluator {
    static func recommendation(
        homePlugTypes: [String],
        destinationPlugTypes: [String]
    ) -> NextTripRequirementRecommendation {
        let homeTypes = Set(homePlugTypes)
        let destinationTypes = Set(destinationPlugTypes)
        guard !homeTypes.isEmpty, !destinationTypes.isEmpty else {
            return .homeCountryUnavailable
        }

        return homeTypes.isSubset(of: destinationTypes)
            ? .plugAdapterNotExpected
            : .adapterRecommended
    }
}

private extension CountryElectricalProfile {
    var hasCompleteElectricalData: Bool {
        !voltage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !plugTypes.isEmpty
    }
}
