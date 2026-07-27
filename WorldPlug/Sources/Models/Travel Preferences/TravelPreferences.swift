import Foundation

// MARK: - TravelPreferences

/// The user-owned data that syncs between devices. Country and plug catalogue data stays local.
struct TravelPreferences: Codable, Equatable, Sendable {
    var homeCountryCode: String
    var savedCountryCodes: [String]
    var nextTrip: NextTrip?
    var favoriteWidgetCountryCode: String?
    var tripChecks: [TripCheck]

    init(
        homeCountryCode: String = "",
        savedCountryCodes: [String] = [],
        nextTrip: NextTrip? = nil,
        favoriteWidgetCountryCode: String? = nil,
        tripChecks: [TripCheck] = []
    ) {
        self.homeCountryCode = homeCountryCode
        self.savedCountryCodes = savedCountryCodes
        self.nextTrip = nextTrip
        self.favoriteWidgetCountryCode = favoriteWidgetCountryCode
        self.tripChecks = tripChecks
    }

    private enum CodingKeys: String, CodingKey {
        case homeCountryCode
        case savedCountryCodes
        case nextTrip
        case favoriteWidgetCountryCode
        case tripChecks
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeCountryCode = try container.decodeIfPresent(String.self, forKey: .homeCountryCode) ?? ""
        savedCountryCodes = try container.decodeIfPresent([String].self, forKey: .savedCountryCodes) ?? []
        nextTrip = try container.decodeIfPresent(NextTrip.self, forKey: .nextTrip)
        favoriteWidgetCountryCode = try container.decodeIfPresent(String.self, forKey: .favoriteWidgetCountryCode)
        tripChecks = try container.decodeIfPresent([TripCheck].self, forKey: .tripChecks) ?? []
    }
}

// MARK: - TripCheck

/// A saved destination and the devices a traveler plans to bring.
struct TripCheck: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    var countryCode: String
    var departureDate: Date
    var returnDate: Date
    var name: String?
    var devices: [TravelDevice]

    init(
        id: UUID = UUID(),
        countryCode: String,
        departureDate: Date = .now,
        returnDate: Date = .now,
        name: String? = nil,
        devices: [TravelDevice] = []
    ) {
        self.id = id
        self.countryCode = countryCode
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.name = name
        self.devices = devices
    }
}

enum TravelDevice: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case phone
    case laptop
    case camera
    case electricShaver
    case hairDryer
    case hairStyler
    case cpap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phone: LocalizationKeys.tripCheckDevicePhone.localized
        case .laptop: LocalizationKeys.tripCheckDeviceLaptop.localized
        case .camera: LocalizationKeys.tripCheckDeviceCamera.localized
        case .electricShaver: LocalizationKeys.tripCheckDeviceShaver.localized
        case .hairDryer: LocalizationKeys.tripCheckDeviceHairDryer.localized
        case .hairStyler: LocalizationKeys.tripCheckDeviceHairStyler.localized
        case .cpap: LocalizationKeys.tripCheckDeviceCPAP.localized
        }
    }

    var symbolName: String {
        switch self {
        case .phone: "iphone"
        case .laptop: "laptopcomputer"
        case .camera: "camera"
        case .electricShaver: "face.smiling"
        case .hairDryer: "wind"
        case .hairStyler: "sparkles"
        case .cpap: "cross.case.fill"
        }
    }

    /// Most modern chargers have a wide input range. High-wattage heat tools should never
    /// be treated as safe across a voltage change without reading their own label.
    var isUsuallyDualVoltage: Bool {
        switch self {
        case .phone, .laptop, .camera, .electricShaver, .cpap: true
        case .hairDryer, .hairStyler: false
        }
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
