import Foundation

// MARK: - TravelPreferences

/// User-owned state that syncs through iCloud. The country and plug catalogue stays local.
public struct TravelPreferences: Codable, Equatable, Sendable {
    public var homeCountryCode: String
    public var savedCountryCodes: [String]
    public var favoriteWidgetCountryCode: String?
    public var trips: [Trip]

    public init(
        homeCountryCode: String = "",
        savedCountryCodes: [String] = [],
        favoriteWidgetCountryCode: String? = nil,
        trips: [Trip] = []
    ) {
        self.homeCountryCode = homeCountryCode
        self.savedCountryCodes = savedCountryCodes
        self.favoriteWidgetCountryCode = favoriteWidgetCountryCode
        self.trips = trips
    }

    public func currentTrip(now: Date = .now, calendar: Calendar = .current) -> Trip? {
        Self.currentTrip(among: trips, now: now, calendar: calendar)
    }

    public static func currentTrip(
        among trips: [Trip],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Trip? {
        let today = calendar.startOfDay(for: now)

        if let ongoing = trips
            .filter({ $0.contains(today, calendar: calendar) })
            .min(by: { $0.departureDate < $1.departureDate }) {
            return ongoing
        }

        return trips
            .filter { calendar.startOfDay(for: $0.departureDate) > today }
            .min(by: { $0.departureDate < $1.departureDate })
    }
}

// MARK: - Trip

public struct Trip: Codable, Equatable, Hashable, Identifiable, Sendable {
    public static let defaultDuration: TimeInterval = 7 * 24 * 60 * 60

    public let id: UUID
    public var countryCode: String
    public var departureDate: Date
    public var returnDate: Date
    public var name: String?
    public var devices: [PackDevice]

    public init(
        id: UUID = UUID(),
        countryCode: String,
        departureDate: Date = .now,
        returnDate: Date = .now + Trip.defaultDuration,
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

    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return calendar.startOfDay(for: departureDate) <= day
            && day <= calendar.startOfDay(for: returnDate)
    }

    public func isPast(now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: now) > calendar.startOfDay(for: returnDate)
    }
}

// MARK: - PackDevice

public struct PackDevice: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var symbolName: String
    public var voltage: String
    public var frequency: String

    public init(
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
