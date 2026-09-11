import Foundation

// MARK: - TravelPreferences

/// The user-owned data that syncs between devices. Country and plug catalogue data stays local.
struct TravelPreferences: Codable, Equatable, Sendable {
    var homeCountryCode: String
    var savedCountryCodes: [String]
    var favoriteWidgetCountryCode: String?
    var trips: [Trip]

    init(
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

    /// The single trip the widgets and Siri speak about. Derived, never chosen by the user: an
    /// in-progress trip wins (the traveler is already there and wants socket information now),
    /// otherwise the soonest upcoming departure. Trips that have already ended are never picked.
    func currentTrip(now: Date = .now, calendar: Calendar = .current) -> Trip? {
        Self.currentTrip(among: trips, now: now, calendar: calendar)
    }

    /// The same rule over a bare trip list.
    ///
    /// Exists so a store that projects `trips` as its own observable property can derive the
    /// current trip from that projection alone. Going through the instance method instead would
    /// read the whole `TravelPreferences` value and re-establish a dependency on every field of
    /// it — the exact thing the projections are there to avoid.
    static func currentTrip(
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

/// A destination, the dates the traveler is there, and the devices they plan to bring.
struct Trip: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// A new trip defaults to a week away from today rather than a zero-length trip on `.now`,
    /// which is never what someone means by "a trip".
    static let defaultDuration: TimeInterval = 7 * 24 * 60 * 60

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

    /// Whether `date` falls inside the trip, comparing whole days so a trip counts as ongoing for
    /// the entirety of both its departure and return day.
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return calendar.startOfDay(for: departureDate) <= day
            && day <= calendar.startOfDay(for: returnDate)
    }

    /// A trip whose return day is already behind us. Kept in the list, shown dimmed, and never
    /// counted against the free-tier trip limit.
    func isPast(now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: now) > calendar.startOfDay(for: returnDate)
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
