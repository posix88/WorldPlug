import SwiftData
import Foundation

@Model
public class Country: Identifiable, Decodable, Hashable {
    public var id: String { code }
    public let name: String
    public let code: String
    public let voltage: String
    public let frequency: String
    public let flagUnicode: String
    public let plugTypes: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case code = "country_code"
        case voltage
        case frequency
        case flagUnicode = "flag_emoji"
        case plugTypes = "plug_types"
    }

    public init(code: String, voltage: String, frequency: String, flagUnicode: String, plugTypes: [String]) {
        self.name = Locale.current.localizedString(forRegionCode: code) ?? ""
        self.code = code
        self.voltage = voltage
        self.frequency = frequency
        self.flagUnicode = flagUnicode
        self.plugTypes = plugTypes
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(String.self, forKey: .code)
        self.code = code
        self.name = Locale.current.localizedString(forRegionCode: code) ?? ""
        self.voltage = try container.decode(String.self, forKey: .voltage)
        self.frequency = try container.decode(String.self, forKey: .frequency)
        self.flagUnicode = try container.decode(String.self, forKey: .flagUnicode)
        self.plugTypes = try container.decode([String].self, forKey: .plugTypes)
    }
}
