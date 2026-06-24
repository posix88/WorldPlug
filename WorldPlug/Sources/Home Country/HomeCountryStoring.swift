import Foundation

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
    private let key = "home.country.code"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var homeCountryCode: String {
        get { defaults.string(forKey: key) ?? "" }
        nonmutating set { defaults.set(newValue.isEmpty ? nil : newValue, forKey: key) }
    }
}
