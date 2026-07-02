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
    private let legacyDefaults: UserDefaults
    private let key = AppGroup.homeCountryCodeKey

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier),
        legacyDefaults: UserDefaults = .standard
    ) {
        self.defaults = defaults ?? legacyDefaults
        self.legacyDefaults = legacyDefaults
        migrateLegacyValueIfNeeded()
    }

    var homeCountryCode: String {
        get { defaults.string(forKey: key) ?? legacyDefaults.string(forKey: key) ?? "" }
        nonmutating set {
            let value = newValue.isEmpty ? nil : newValue
            defaults.set(value, forKey: key)
            legacyDefaults.set(value, forKey: key)
        }
    }

    private func migrateLegacyValueIfNeeded() {
        guard defaults.string(forKey: key) == nil,
              let legacyValue = legacyDefaults.string(forKey: key),
              !legacyValue.isEmpty else {
            return
        }

        defaults.set(legacyValue, forKey: key)
    }
}
