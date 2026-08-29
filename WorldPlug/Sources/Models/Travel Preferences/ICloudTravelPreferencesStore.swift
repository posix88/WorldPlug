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
    func setNextTrip(_ trip: NextTrip?)
    func saveTripCheck(_ tripCheck: TripCheck)
    func removeTripCheck(id: UUID)
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
        analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker()
    ) {
        self.iCloudStore = iCloudStore
        self.appGroupDefaults = appGroupDefaults ?? .standard
        self.analyticsTracker = analyticsTracker
        iCloudStore.synchronize()
        let loadedPreferences = Self.loadPreferences(from: iCloudStore)
        self.preferences = Self.removingExpiredTrip(from: loadedPreferences)

        if preferences != loadedPreferences {
            persist()
        } else {
            mirrorWidgetValues()
        }

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
        iCloudStore.synchronize()
        preferences = Self.removingExpiredTrip(from: Self.loadPreferences(from: iCloudStore))
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

    func setNextTrip(_ trip: NextTrip?) {
        let previousTrip = preferences.nextTrip
        var updatedPreferences = preferences
        updatedPreferences.nextTrip = trip
        preferences = Self.removingExpiredTrip(from: updatedPreferences)

        switch (previousTrip == nil, trip == nil) {
        case (true, false):
            analyticsTracker.track(.nextTripCreated)
        case (false, false):
            analyticsTracker.track(.nextTripUpdated)
        case (false, true):
            analyticsTracker.track(.nextTripRemoved)
        case (true, true):
            break
        }
    }

    func saveTripCheck(_ tripCheck: TripCheck) {
        var updatedPreferences = preferences
        if let index = updatedPreferences.tripChecks.firstIndex(where: { $0.id == tripCheck.id }) {
            updatedPreferences.tripChecks[index] = tripCheck
        } else {
            updatedPreferences.tripChecks.append(tripCheck)
        }
        preferences = updatedPreferences
    }

    func removeTripCheck(id: UUID) {
        var updatedPreferences = preferences
        updatedPreferences.tripChecks.removeAll { $0.id == id }
        preferences = updatedPreferences
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
        appGroupDefaults.set(preferences.nextTrip?.returnDate, forKey: AppGroup.nextTripReturnDateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readPreferencesSnapshot(
        from store: NSUbiquitousKeyValueStore = .default
    ) -> TravelPreferences {
        store.synchronize()
        return removingExpiredTrip(from: loadPreferences(from: store))
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

    private static func removingExpiredTrip(
        from preferences: TravelPreferences,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TravelPreferences {
        guard let returnDate = preferences.nextTrip?.returnDate,
              calendar.startOfDay(for: now) > calendar.startOfDay(for: returnDate) else {
            return preferences
        }

        var updatedPreferences = preferences
        updatedPreferences.nextTrip = nil
        return updatedPreferences
    }
}

// MARK: - NullTravelPreferencesStore

final class NullTravelPreferencesStore: TravelPreferencesStoring {
    @MainActor var preferences = TravelPreferences()

    @MainActor func reloadFromICloud() {}
    @MainActor func toggleSavedCountry(code: String) {}
    @MainActor func isSavedCountry(code: String) -> Bool { false }
    @MainActor func setNextTrip(_ trip: NextTrip?) {}
    @MainActor func saveTripCheck(_ tripCheck: TripCheck) {}
    @MainActor func removeTripCheck(id: UUID) {}
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

    func setNextTrip(_ trip: NextTrip?) {
        preferences.nextTrip = trip
    }

    func saveTripCheck(_ tripCheck: TripCheck) {
        if let index = preferences.tripChecks.firstIndex(where: { $0.id == tripCheck.id }) {
            preferences.tripChecks[index] = tripCheck
        } else {
            preferences.tripChecks.append(tripCheck)
        }
    }

    func removeTripCheck(id: UUID) {
        preferences.tripChecks.removeAll { $0.id == id }
    }

    func setFavoriteWidgetCountry(code: String?) {
        preferences.favoriteWidgetCountryCode = code?.uppercased()
    }
}
#endif

extension EnvironmentValues {
    @Entry var travelPreferencesStore: any TravelPreferencesStoring = NullTravelPreferencesStore()
}
