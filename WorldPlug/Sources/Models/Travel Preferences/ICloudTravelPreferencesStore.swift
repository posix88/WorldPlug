import Analytics
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
    func saveTrip(_ trip: Trip)
    func removeTrip(id: UUID)
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
    private let analyticsTracker: any AnalyticsTracker
    private let usesICloudPersistence: Bool
    /// `nonisolated(unsafe)`: written exactly once in `init` and read exactly once in `deinit`.
    /// Both run at a point where no other code can be concurrently touching `self`, so no
    /// additional synchronization is needed even though the class is `@MainActor`-isolated
    /// (a plain `@MainActor` stored property can't be read from `deinit`, which is nonisolated).
    private nonisolated(unsafe) var externalChangeObserver: NSObjectProtocol?

    var preferences: TravelPreferences {
        didSet {
            // Avoid re-writing (and re-`synchronize()`-ing) iCloud with data that hasn't
            // actually changed — important now that `reloadFromICloud()` also runs in response
            // to `didChangeExternallyNotification`, or every incoming external change would
            // immediately echo an identical write straight back to iCloud.
            guard preferences != oldValue else {
                return
            }

            persist()
        }
    }

    init(
        iCloudStore: NSUbiquitousKeyValueStore = .default,
        appGroupDefaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier),
        analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker(),
        inMemoryPreferences: TravelPreferences? = nil
    ) {
        self.iCloudStore = iCloudStore
        self.appGroupDefaults = appGroupDefaults ?? .standard
        self.analyticsTracker = analyticsTracker
        self.usesICloudPersistence = inMemoryPreferences == nil

        if let inMemoryPreferences {
            self.preferences = inMemoryPreferences
            mirrorWidgetValues()
            return
        }

        iCloudStore.synchronize()
        self.preferences = Self.loadPreferences(from: iCloudStore)
        mirrorWidgetValues()
        observeExternalChanges()
    }

    deinit {
        if let externalChangeObserver {
            NotificationCenter.default.removeObserver(externalChangeObserver)
        }
    }

    /// Picks up changes written by another device (or another process on this device) through
    /// the same iCloud account. Without this, a session already in the foreground never sees a
    /// change made elsewhere until it backgrounds and re-foregrounds — see
    /// `AppCoordinator.sceneBecameActive()`, which is otherwise the only caller of
    /// `reloadFromICloud()`.
    private func observeExternalChanges() {
        externalChangeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadFromICloud()
            }
        }
    }

    func reloadFromICloud() {
        guard usesICloudPersistence else {
            return
        }

        iCloudStore.synchronize()
        let loadedPreferences = Self.loadPreferences(from: iCloudStore)

        guard loadedPreferences != preferences else {
            // Nothing changed, so `preferences`' `didSet` won't fire — but the widgets' trip is
            // *derived* from today's date, so it can go stale purely through the passage of time
            // (a trip ends, the one after it becomes current). Re-mirror anyway: this runs on
            // every foreground (`AppCoordinator.sceneBecameActive()` →
            // `HomeCountryViewModel.refreshHomeCountry()` → here), which is the cheapest place to
            // notice that the calendar moved on without us.
            mirrorWidgetValues()
            return
        }

        preferences = loadedPreferences
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
            analyticsTracker.track(.countryUnsaved)
        } else {
            updatedPreferences.savedCountryCodes.append(countryCode)
            analyticsTracker.track(.countrySaved)
        }

        preferences = updatedPreferences
    }

    func isSavedCountry(code: String) -> Bool {
        preferences.savedCountryCodes.contains(Self.normalizedCountryCode(code))
    }

    func saveTrip(_ trip: Trip) {
        var updatedPreferences = preferences
        if let index = updatedPreferences.trips.firstIndex(where: { $0.id == trip.id }) {
            guard updatedPreferences.trips[index] != trip else {
                return
            }

            updatedPreferences.trips[index] = trip
            preferences = updatedPreferences
            analyticsTracker.track(.tripUpdated)
        } else {
            updatedPreferences.trips.append(trip)
            preferences = updatedPreferences
            analyticsTracker.track(.tripCreated)
        }
    }

    func removeTrip(id: UUID) {
        var updatedPreferences = preferences
        updatedPreferences.trips.removeAll { $0.id == id }

        guard updatedPreferences != preferences else {
            return
        }

        preferences = updatedPreferences
        analyticsTracker.track(.tripRemoved)
    }

    func setFavoriteWidgetCountry(code: String?) {
        let countryCode = code.map(Self.normalizedCountryCode)
        guard let countryCode else {
            var updatedPreferences = preferences
            let hadFavoriteWidgetCountry = updatedPreferences.favoriteWidgetCountryCode != nil
            updatedPreferences.favoriteWidgetCountryCode = nil
            preferences = updatedPreferences
            if hadFavoriteWidgetCountry {
                analyticsTracker.track(.favoriteWidgetCountryCleared)
            }
            return
        }
        guard preferences.savedCountryCodes.contains(countryCode) else {
            return
        }

        var updatedPreferences = preferences
        guard updatedPreferences.favoriteWidgetCountryCode != countryCode else {
            return
        }

        updatedPreferences.favoriteWidgetCountryCode = countryCode
        preferences = updatedPreferences
        analyticsTracker.track(.favoriteWidgetCountrySelected)
    }

    private func persist() {
        guard usesICloudPersistence else {
            mirrorWidgetValues()
            return
        }
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        iCloudStore.set(data, forKey: Self.preferencesKey)
        iCloudStore.synchronize()
        mirrorWidgetValues()
    }

    private func mirrorWidgetValues() {
        // The widgets read a single trip from the App Group. Which one that is is derived here
        // rather than stored, so nothing needs to be re-written when a trip simply starts or ends.
        let currentTrip = preferences.currentTrip()
        appGroupDefaults.set(preferences.favoriteWidgetCountryCode, forKey: AppGroup.favoriteCountryCodeKey)
        appGroupDefaults.set(currentTrip?.countryCode, forKey: AppGroup.nextTripCountryCodeKey)
        appGroupDefaults.set(currentTrip?.departureDate, forKey: AppGroup.nextTripDepartureDateKey)
        appGroupDefaults.set(currentTrip?.returnDate, forKey: AppGroup.nextTripReturnDateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readPreferencesSnapshot(
        from store: NSUbiquitousKeyValueStore = .default
    ) -> TravelPreferences {
        store.synchronize()
        return loadPreferences(from: store)
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
    @MainActor func saveTrip(_ trip: Trip) {}
    @MainActor func removeTrip(id: UUID) {}
    @MainActor func setFavoriteWidgetCountry(code: String?) {}
}

#if DEBUG
@Observable
@MainActor
final class PreviewTravelPreferencesStore: TravelPreferencesStoring {
    var preferences: TravelPreferences

    init(preferences: TravelPreferences = TravelPreferences()) {
        self.preferences = preferences
    }

    func reloadFromICloud() {}

    func toggleSavedCountry(code: String) {
        let countryCode = code.uppercased()
        if let index = preferences.savedCountryCodes.firstIndex(of: countryCode) {
            preferences.savedCountryCodes.remove(at: index)
        } else {
            preferences.savedCountryCodes.append(countryCode)
        }
    }

    func isSavedCountry(code: String) -> Bool {
        preferences.savedCountryCodes.contains(code.uppercased())
    }

    func saveTrip(_ trip: Trip) {
        if let index = preferences.trips.firstIndex(where: { $0.id == trip.id }) {
            preferences.trips[index] = trip
        } else {
            preferences.trips.append(trip)
        }
    }

    func removeTrip(id: UUID) {
        preferences.trips.removeAll { $0.id == id }
    }

    func setFavoriteWidgetCountry(code: String?) {
        preferences.favoriteWidgetCountryCode = code?.uppercased()
    }
}
#endif

extension EnvironmentValues {
    @Entry var travelPreferencesStore: any TravelPreferencesStoring = NullTravelPreferencesStore()
}
