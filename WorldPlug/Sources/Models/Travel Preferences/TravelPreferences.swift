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
}

// MARK: - TripCheck

/// A saved destination and the devices a traveler plans to bring.
struct TripCheck: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    var countryCode: String
    var departureDate: Date
    var returnDate: Date
    var name: String?
    var devices: [PackDevice]

    init(
        id: UUID = UUID(),
        countryCode: String,
        departureDate: Date = .now,
        returnDate: Date = .now,
        name: String? = nil,
        devices: [PackDevice] = []
    ) {
        self.id = id
        self.countryCode = countryCode
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.name = name
        self.devices = devices
    }
}

// MARK: - PackDevice

struct PackDevice: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var symbolName: String
    var voltage: String
    var frequency: String

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "powerplug.fill",
        voltage: String,
        frequency: String = ""
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.voltage = voltage
        self.frequency = frequency
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
