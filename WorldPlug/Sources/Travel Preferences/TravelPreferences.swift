import Foundation

// MARK: - TravelPreferences

/// The user-owned data that syncs between devices. Country and plug catalogue data stays local.
struct TravelPreferences: Codable, Equatable, Sendable {
    var homeCountryCode: String
    var savedCountryCodes: [String]
    var nextTrip: NextTrip?
    var favoriteWidgetCountryCode: String?

    init(
        homeCountryCode: String = "",
        savedCountryCodes: [String] = [],
        nextTrip: NextTrip? = nil,
        favoriteWidgetCountryCode: String? = nil
    ) {
        self.homeCountryCode = homeCountryCode
        self.savedCountryCodes = savedCountryCodes
        self.nextTrip = nextTrip
        self.favoriteWidgetCountryCode = favoriteWidgetCountryCode
    }

    private enum CodingKeys: String, CodingKey {
        case homeCountryCode
        case savedCountryCodes
        case nextTrip
        case favoriteWidgetCountryCode
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeCountryCode = try container.decodeIfPresent(String.self, forKey: .homeCountryCode) ?? ""
        savedCountryCodes = try container.decodeIfPresent([String].self, forKey: .savedCountryCodes) ?? []
        nextTrip = try container.decodeIfPresent(NextTrip.self, forKey: .nextTrip)
        favoriteWidgetCountryCode = try container.decodeIfPresent(String.self, forKey: .favoriteWidgetCountryCode)
    }
}

// MARK: - NextTrip

struct NextTrip: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var countryCode: String
    var departureDate: Date
    var returnDate: Date
    var name: String?

    init(
        id: UUID = UUID(),
        countryCode: String,
        departureDate: Date,
        returnDate: Date,
        name: String? = nil
    ) {
        self.id = id
        self.countryCode = countryCode
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.name = name
    }

}
