import Foundation

// MARK: - TravelPreferences

/// The user-owned data that syncs between devices. Country and plug catalogue data stays local.
struct TravelPreferences: Codable, Equatable, Sendable {
    var savedCountryCodes: [String] = []
    var nextTrip: NextTrip?
    var favoriteWidgetCountryCode: String?
}

// MARK: - NextTrip

struct NextTrip: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var countryCode: String
    var departureDate: Date
    var returnDate: Date?
    var name: String?

    init(
        id: UUID = UUID(),
        countryCode: String,
        departureDate: Date,
        returnDate: Date? = nil,
        name: String? = nil
    ) {
        self.id = id
        self.countryCode = countryCode
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.name = name
    }
}
