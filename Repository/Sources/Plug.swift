import SwiftData
import Foundation

@Model
public class Plug: Identifiable, Decodable, Hashable {
    public let id: String
    public let name: String
    public let info: String
    public let images: [URL]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case plug_images
    }

    public init(id: String, name: String, info: String, images: [URL]) {
        self.id = id
        self.name = name
        self.info = info
        self.images = images
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.info = try container.decode(String.self, forKey: .description)
        let images: [String] = try container.decode([String].self, forKey: .plug_images)
        self.images = images.compactMap { URL(string: $0 ) }
    }
}
