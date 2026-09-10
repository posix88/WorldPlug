import Foundation
import Repository

// MARK: - HomeCountryStoring

/// Abstracts the persistence layer for the user's home country selection.
/// Inject a test double in unit tests to avoid touching UserDefaults.
protocol HomeCountryStoring {
    /// The stored country code, or an empty string when none is set.
    var homeCountryCode: String { get nonmutating set }
}

// MARK: - UserDefaultsHomeCountryStore

struct UserDefaultsHomeCountryStore: HomeCountryStoring {
    private let defaults: UserDefaults
    private let key = AppGroup.homeCountryCodeKey

    /// Falls back to `.standard` only for the case where the App Group suite can't be opened at
    /// all, so the app still works (minus widgets) instead of losing the selection outright.
    init(defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)) {
        self.defaults = defaults ?? .standard
    }

    var homeCountryCode: String {
        get { defaults.string(forKey: key) ?? "" }
        nonmutating set {
            defaults.set(newValue.isEmpty ? nil : newValue, forKey: key)
        }
    }
}
