import Foundation
import SwiftData

// MARK: - PlugSpecifications

public struct PlugSpecifications: Codable {
    public let pinDiameter: String
    public let pinSpacing: String
    public let ratedAmperage: String
    public let alsoKnownAs: String

    public init(pinDiameter: String, pinSpacing: String, ratedAmperage: String, alsoKnownAs: String) {
        self.pinDiameter = pinDiameter
        self.pinSpacing = pinSpacing
        self.ratedAmperage = ratedAmperage
        self.alsoKnownAs = alsoKnownAs
    }

    private enum CodingKeys: String, CodingKey {
        case pinDiameter = "pin_diameter"
        case pinSpacing = "pin_spacing"
        case ratedAmperage = "rated_amperage"
        case alsoKnownAs = "also_known_as"
    }
}

// MARK: - SchemaV4.Plug

extension SchemaV4 {
    @Model
    public final class Plug: Identifiable, Hashable {
        @Attribute(.unique)
        public var id: String

        public var plugType: PlugType
        public var name: String
        public var shortInfo: String
        public var info: String
        public var images: [URL]
        public var pinDiameter: String
        public var pinSpacing: String
        public var ratedAmperage: String
        public var alsoKnownAs: String
        @Relationship(inverse: \Country.plugs) var countries: [Country]

        public init(
            id: String,
            name: String,
            shortInfo: String,
            info: String,
            images: [URL],
            specifications: PlugSpecifications,
            countries: [Country] = []
        ) {
            self.id = id
            self.plugType = PlugType(rawValue: id) ?? .unknown
            self.name = name
            self.info = info
            self.images = images
            self.pinDiameter = specifications.pinDiameter
            self.pinSpacing = specifications.pinSpacing
            self.ratedAmperage = specifications.ratedAmperage
            self.alsoKnownAs = specifications.alsoKnownAs
            self.countries = countries
            self.shortInfo = shortInfo
        }
    }
}

// MARK: - PlugType

public enum PlugType: String, Codable, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case unknown
}

// MARK: - PlugDecodable

final class PlugDecodable: Decodable {
    public let id: String
    public let name: String
    public let info: String
    public let images: [URL]
    public let shortInfo: String
    public let specifications: PlugSpecifications

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case plug_images
        case short_description
        case specifications
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.info = try container.decode(String.self, forKey: .description)
        let images: [String] = try container.decode([String].self, forKey: .plug_images)
        self.images = images.compactMap { URL(string: $0) }
        self.shortInfo = try container.decode(String.self, forKey: .short_description)
        self.specifications = try container.decode(PlugSpecifications.self, forKey: .specifications)
    }
}
