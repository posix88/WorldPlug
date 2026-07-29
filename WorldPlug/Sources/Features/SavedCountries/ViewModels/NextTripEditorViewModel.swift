import Foundation
import Observation
import Repository

// MARK: - NextTripEditorViewModel

@Observable
@MainActor
final class NextTripEditorViewModel {
    var trip: NextTrip
    var returnDate: Date
    let isExisting: Bool

    init(trip: NextTrip?, countries: [Country]) {
        let initialTrip = trip ?? NextTrip(
            countryCode: countries.first?.code ?? "",
            departureDate: .now,
            returnDate: .now
        )
        self.trip = initialTrip
        self.returnDate = initialTrip.returnDate
        self.isExisting = trip != nil
    }

    var canSave: Bool { !trip.countryCode.isEmpty }

    func departureDateChanged() {
        if returnDate < trip.departureDate {
            returnDate = trip.departureDate
        }
    }

    func save() -> NextTrip {
        trip.returnDate = returnDate
        trip.name = normalizedName
        return trip
    }

    private var normalizedName: String? {
        let name = trip.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }
}
