import Foundation
import Observation

@Observable
@MainActor
final class AppNavigationModel {
    static let shared = AppNavigationModel()

    var deepLinkedCountryCode: String?
    var selectedTab = 0

    private init() {}

    func openCountry(code: String) {
        selectedTab = 0
        deepLinkedCountryCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
