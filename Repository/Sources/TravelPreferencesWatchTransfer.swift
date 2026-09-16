import Foundation

/// Encodes travel preferences for the paired-device application context.
///
/// iCloud remains the source of truth. This transfer gives a newly installed companion a
/// current snapshot while iCloud's initial synchronization completes.
public enum TravelPreferencesWatchTransfer {
    public static let applicationContextKey = "travel.preferences.watch-transfer.v1"

    public static func applicationContext(for preferences: TravelPreferences) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return [:]
        }

        return [applicationContextKey: data]
    }

    public static func preferences(from applicationContext: [String: Any]) -> TravelPreferences? {
        guard let data = applicationContext[applicationContextKey] as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(TravelPreferences.self, from: data)
    }
}
