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
        self.homeCountryCode = try container.decodeIfPresent(String.self, forKey: .homeCountryCode) ?? ""
        self.savedCountryCodes = try container.decodeIfPresent([String].self, forKey: .savedCountryCodes) ?? []
        self.nextTrip = try container.decodeIfPresent(NextTrip.self, forKey: .nextTrip)
        self.favoriteWidgetCountryCode = try container.decodeIfPresent(String.self, forKey: .favoriteWidgetCountryCode)
        self.tripChecks = try container.decodeIfPresent([TripCheck].self, forKey: .tripChecks) ?? []
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

    private enum CodingKeys: String, CodingKey {
        case id
        case countryCode
        case departureDate
        case returnDate
        case name
        case devices
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        self.departureDate = try container.decodeIfPresent(Date.self, forKey: .departureDate) ?? .now
        self.returnDate = try container.decodeIfPresent(Date.self, forKey: .returnDate) ?? departureDate
        self.name = try container.decodeIfPresent(String.self, forKey: .name)

        if let savedDevices = try? container.decode([PackDevice].self, forKey: .devices) {
            self.devices = savedDevices
        } else {
            let legacyDevices = try container.decodeIfPresent([TravelDevice].self, forKey: .devices) ?? []
            self.devices = legacyDevices.map(PackDevice.init(legacyDevice:))
        }
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

    init(legacyDevice: TravelDevice) {
        self.init(name: legacyDevice.title, symbolName: legacyDevice.symbolName, voltage: "")
    }
}

// MARK: - TravelDevice

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
