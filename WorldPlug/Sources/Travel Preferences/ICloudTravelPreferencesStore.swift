import Foundation
import Observation
import Repository
import SwiftUI
import WidgetKit

// MARK: - TravelPreferencesStoring

@MainActor
protocol TravelPreferencesStoring: AnyObject {
    var preferences: TravelPreferences { get set }

    /// Reloads values that arrived from another device through iCloud.
    func reloadFromICloud()
    func toggleSavedCountry(code: String)
    func isSavedCountry(code: String) -> Bool
    func setNextTrip(_ trip: NextTrip?)
    func setFavoriteWidgetCountry(code: String?)
}

// MARK: - ICloudTravelPreferencesStore

/// Persists the small amount of user-owned travel data through iCloud key-value storage.
/// Widget-facing values are mirrored to the App Group for WidgetKit timelines.
@Observable
@MainActor
final class ICloudTravelPreferencesStore: TravelPreferencesStoring {
    private static let preferencesKey = "travel.preferences.v1"

    private let iCloudStore: NSUbiquitousKeyValueStore
    private let appGroupDefaults: UserDefaults

    var preferences: TravelPreferences {
        didSet {
            persist()
        }
    }

    init(
        iCloudStore: NSUbiquitousKeyValueStore = .default,
        appGroupDefaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)
    ) {
        self.iCloudStore = iCloudStore
        self.appGroupDefaults = appGroupDefaults ?? .standard
        iCloudStore.synchronize()
        preferences = Self.loadPreferences(from: iCloudStore)
        mirrorWidgetValues()
    }

    func reloadFromICloud() {
        iCloudStore.synchronize()
        preferences = Self.loadPreferences(from: iCloudStore)
    }

    func toggleSavedCountry(code: String) {
        let countryCode = Self.normalizedCountryCode(code)
        guard !countryCode.isEmpty else {
            return
        }

        var updatedPreferences = preferences
        if let index = updatedPreferences.savedCountryCodes.firstIndex(of: countryCode) {
            updatedPreferences.savedCountryCodes.remove(at: index)

            if updatedPreferences.favoriteWidgetCountryCode == countryCode {
                updatedPreferences.favoriteWidgetCountryCode = nil
            }
        } else {
            updatedPreferences.savedCountryCodes.append(countryCode)
        }

        preferences = updatedPreferences
    }

    func isSavedCountry(code: String) -> Bool {
        preferences.savedCountryCodes.contains(Self.normalizedCountryCode(code))
    }

    func setNextTrip(_ trip: NextTrip?) {
        var updatedPreferences = preferences
        updatedPreferences.nextTrip = trip
        preferences = updatedPreferences
    }

    func setFavoriteWidgetCountry(code: String?) {
        let countryCode = code.map(Self.normalizedCountryCode)
        guard let countryCode else {
            var updatedPreferences = preferences
            updatedPreferences.favoriteWidgetCountryCode = nil
            preferences = updatedPreferences
            return
        }

        guard preferences.savedCountryCodes.contains(countryCode) else {
            return
        }

        var updatedPreferences = preferences
        updatedPreferences.favoriteWidgetCountryCode = countryCode
        preferences = updatedPreferences
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        iCloudStore.set(data, forKey: Self.preferencesKey)
        iCloudStore.synchronize()
        mirrorWidgetValues()
    }

    private func mirrorWidgetValues() {
        appGroupDefaults.set(preferences.favoriteWidgetCountryCode, forKey: AppGroup.favoriteCountryCodeKey)
        appGroupDefaults.set(preferences.nextTrip?.countryCode, forKey: AppGroup.nextTripCountryCodeKey)
        appGroupDefaults.set(preferences.nextTrip?.departureDate, forKey: AppGroup.nextTripDepartureDateKey)
        WidgetCenter.shared.reloadAllTimelines()
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

    private static func normalizedCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

// MARK: - NullTravelPreferencesStore

final class NullTravelPreferencesStore: TravelPreferencesStoring {
    @MainActor var preferences = TravelPreferences()

    @MainActor func reloadFromICloud() {}
    @MainActor func toggleSavedCountry(code: String) {}
    @MainActor func isSavedCountry(code: String) -> Bool { false }
    @MainActor func setNextTrip(_ trip: NextTrip?) {}
    @MainActor func setFavoriteWidgetCountry(code: String?) {}
}

extension EnvironmentValues {
    @Entry var travelPreferencesStore: any TravelPreferencesStoring = NullTravelPreferencesStore()
}
