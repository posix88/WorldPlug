import Foundation
import Observation
import Repository

// MARK: - TripEditorViewModel

/// Backs the trip *creation and editing* form: destination, dates, name. Devices are deliberately
/// not here — a trip is created first and devices are added afterwards from `TripDetailView`,
/// which is also the only place that needs the premium entitlement.
@Observable
@MainActor
final class TripEditorViewModel {
    private let existingTripID: UUID?

    var trip: Trip

    /// A new trip starts with **no** destination. There used to be a prefill that fell back to
    /// `countries.first`, which silently proposed Andorra; an unset destination keeps `canSave`
    /// false until the user picks one on purpose.
    init(trip: Trip? = nil) {
        self.existingTripID = trip?.id
        self.trip = trip ?? Trip(countryCode: "")
        clampReturnDate()
    }

    var isExisting: Bool { existingTripID != nil }

    var canSave: Bool {
        !trip.countryCode.isEmpty && trip.returnDate >= trip.departureDate
    }

    /// Bound directly by the return-date picker so the invariant holds while editing, not only on
    /// save. `init` clamps too, so a trip that somehow arrives inverted is fixed on open.
    var returnDate: Date {
        get { trip.returnDate }
        set { trip.returnDate = max(newValue, trip.departureDate) }
    }

    func departureDateChanged() {
        clampReturnDate()
    }

    func save() -> Trip {
        var savedTrip = trip
        let trimmedName = trip.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        savedTrip.name = (trimmedName?.isEmpty ?? true) ? nil : trimmedName
        return savedTrip
    }

    private func clampReturnDate() {
        if trip.returnDate < trip.departureDate {
            trip.returnDate = trip.departureDate
        }
    }
}
