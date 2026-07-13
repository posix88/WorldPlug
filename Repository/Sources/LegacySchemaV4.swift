import SwiftData
import Foundation

// MARK: - SchemaV4 Migration Snapshot

extension SchemaV4 {
    @Model
    public final class Country {
        @Attribute(.unique)
        public var code: String
        public var name: String
        public var voltage: String
        public var frequency: String
        public var flagUnicode: String
        public var plugs: [Plug]

        public init(code: String, name: String, voltage: String, frequency: String, flagUnicode: String, plugs: [Plug] = []) {
            self.code = code
            self.name = name
            self.voltage = voltage
            self.frequency = frequency
            self.flagUnicode = flagUnicode
            self.plugs = plugs
        }
    }

    @Model
    public final class Plug {
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
            plugType: PlugType,
            name: String,
            shortInfo: String,
            info: String,
            images: [URL],
            pinDiameter: String,
            pinSpacing: String,
            ratedAmperage: String,
            alsoKnownAs: String,
            countries: [Country] = []
        ) {
            self.id = id
            self.plugType = plugType
            self.name = name
            self.shortInfo = shortInfo
            self.info = info
            self.images = images
            self.pinDiameter = pinDiameter
            self.pinSpacing = pinSpacing
            self.ratedAmperage = ratedAmperage
            self.alsoKnownAs = alsoKnownAs
            self.countries = countries
        }
    }
}
