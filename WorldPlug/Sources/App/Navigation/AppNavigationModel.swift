import Foundation
import Observation

// MARK: - AppTab

enum AppTab: Hashable {
    case countries
    case tripCheck
    case saved
}

// MARK: - AppNavigationModel

@Observable
@MainActor
final class AppNavigationModel {
    static let shared = AppNavigationModel()

    var deepLinkedCountryCode: String?
    var selectedTab = AppTab.countries

    private init() {}

    func openCountry(code: String) {
        selectedTab = .countries
        deepLinkedCountryCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
