import Foundation

// MARK: - TravelPreferencesStoring

@MainActor
protocol TravelPreferencesStoring: AnyObject {
    var preferences: TravelPreferences { get set }

    /// Reloads values that arrived from another device through iCloud.
    func reloadFromICloud()
}

// MARK: - ICloudTravelPreferencesStore

/// Persists the small amount of user-owned travel data through iCloud key-value storage.
/// Widget-facing values are mirrored to the App Group when their UI is introduced.
@MainActor
final class ICloudTravelPreferencesStore: TravelPreferencesStoring {
    private static let preferencesKey = "travel.preferences.v1"

    private let iCloudStore: NSUbiquitousKeyValueStore

    var preferences: TravelPreferences {
        didSet {
            persist()
        }
    }

    init(iCloudStore: NSUbiquitousKeyValueStore = .default) {
        self.iCloudStore = iCloudStore
        iCloudStore.synchronize()
        preferences = Self.loadPreferences(from: iCloudStore)
    }

    func reloadFromICloud() {
        iCloudStore.synchronize()
        preferences = Self.loadPreferences(from: iCloudStore)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        iCloudStore.set(data, forKey: Self.preferencesKey)
        iCloudStore.synchronize()
    }

    private static func loadPreferences(
        from store: NSUbiquitousKeyValueStore
    ) -> TravelPreferences {
        guard let data = store.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(TravelPreferences.self, from: data) else {
            return TravelPreferences()
        }

        return preferences
    }
}
