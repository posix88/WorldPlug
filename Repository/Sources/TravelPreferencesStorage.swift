import Foundation

// MARK: - TravelPreferencesStorage

/// Shared wire format for iPhone, Watch, widgets and App Intents.
///
/// This intentionally owns only iCloud key-value encoding. Each target layers its own
/// observation, analytics and UI policy over it.
public enum TravelPreferencesStorage {
    private static let key = "travel.preferences.v1"

    public static func load(from store: NSUbiquitousKeyValueStore = .default) -> TravelPreferences {
        store.synchronize()

        guard let data = store.data(forKey: key),
              let preferences = try? JSONDecoder().decode(TravelPreferences.self, from: data) else {
            return TravelPreferences()
        }

        return preferences
    }

    public static func persist(
        _ preferences: TravelPreferences,
        to store: NSUbiquitousKeyValueStore = .default
    ) {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        store.set(data, forKey: key)
        store.synchronize()
    }
}
