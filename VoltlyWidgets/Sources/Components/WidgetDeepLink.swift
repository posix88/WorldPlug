import Foundation

enum WidgetDeepLink {
    static var premium: URL? {
        URL(string: "voltly://premium?source=widget")
    }

    static func country(_ countryCode: String?) -> URL? {
        guard let countryCode, !countryCode.isEmpty else {
            return nil
        }

        return URL(string: "voltly://country/\(countryCode)")
    }
}
