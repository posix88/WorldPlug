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
        // Enforce the same "return date can't precede departure" invariant at construction that
        // `departureDateChanged()` enforces reactively — otherwise a trip built from a source
        // that never went through this editor (a future migration, a corrupted/hand-edited
        // iCloud KV record) could start the picker already in an inconsistent state.
        self.returnDate = max(initialTrip.returnDate, initialTrip.departureDate)
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
