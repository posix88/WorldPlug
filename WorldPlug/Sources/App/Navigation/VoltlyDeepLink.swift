import Foundation

enum VoltlyDeepLink {
    private static let scheme = "voltly"

    static func countryCode(from url: URL) -> String? {
        guard url.scheme == scheme,
              url.host == "country",
              let code = url.pathComponents.dropFirst().first else {
            return nil
        }
        return normalizedCountryCode(code)
    }

    static func isPremiumURL(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "premium"
    }

    private static func normalizedCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
