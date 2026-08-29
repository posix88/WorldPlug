import CryptoKit
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
        let decodedID = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.id = decodedID
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        self.departureDate = try container.decodeIfPresent(Date.self, forKey: .departureDate) ?? .now
        self.returnDate = try container.decodeIfPresent(Date.self, forKey: .returnDate) ?? departureDate
        self.name = try container.decodeIfPresent(String.self, forKey: .name)

        if let savedDevices = try? container.decode([PackDevice].self, forKey: .devices) {
            self.devices = savedDevices
        } else {
            let legacyDevices = try container.decodeIfPresent([TravelDevice].self, forKey: .devices) ?? []
            self.devices = legacyDevices.enumerated().map { index, device in
                PackDevice(legacyDevice: device, tripID: decodedID, index: index)
            }
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

    init(legacyDevice: TravelDevice, tripID: UUID, index: Int) {
        self.init(
            id: Self.legacyIdentifier(device: legacyDevice, tripID: tripID, index: index),
            name: legacyDevice.title,
            symbolName: legacyDevice.symbolName,
            voltage: ""
        )
    }

    private static func legacyIdentifier(device: TravelDevice, tripID: UUID, index: Int) -> UUID {
        let input = Data("\(tripID.uuidString)|\(index)|\(device.rawValue)".utf8)
        var bytes = Array(SHA256.hash(data: input).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
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
