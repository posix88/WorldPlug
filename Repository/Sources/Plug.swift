import SwiftData
import Foundation

extension SchemaV2 {
    @Model
    public class Plug: Identifiable, Hashable {
        @Attribute(.unique)
        public var id: String

        public var plugType: PlugType
        public var name: String
        public var shortInfo: String
        public var info: String
        public var images: [URL]
        @Relationship(inverse: \Country.plugs) var countries: [Country]

        public init(id: String, name: String, shortInfo: String, info: String, images: [URL], countries: [Country] = []) {
            self.id = id
            self.plugType = PlugType(rawValue: id) ?? .unknown
            self.name = name
            self.info = info
            self.images = images
            self.countries = countries
            self.shortInfo = shortInfo
        }
    }
}

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

final class PlugDecodable: Decodable {
    public let id: String
    public let name: String
    public let info: String
    public let images: [URL]
    public let shortInfo: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case plug_images
        case short_description
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.info = try container.decode(String.self, forKey: .description)
        let images: [String] = try container.decode([String].self, forKey: .plug_images)
        self.images = images.compactMap { URL(string: $0 ) }
        self.shortInfo = try container.decode(String.self, forKey: .short_description)
    }
}
