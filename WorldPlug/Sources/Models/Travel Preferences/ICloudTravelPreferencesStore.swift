import Analytics
import Foundation
import Observation
import Repository
import SwiftUI
import WidgetKit

// MARK: - TravelPreferencesStoring

@MainActor
protocol TravelPreferencesStoring: AnyObject {
    /// The whole blob, in the shape that round-trips to iCloud.
    ///
    /// **Don't read this from a view body, or from a computed property a view body reads.**
    /// Observation tracks dependencies per *property*, not per field, so touching `preferences`
    /// subscribes the reader to every field of it at once: adding a device to a trip would
    /// invalidate the countries list, the country-detail sheet and the saved tab, none of which
    /// care. Use the projections below for reading; `preferences` is for whole-value writes and
    /// for encoding.
    var preferences: TravelPreferences { get set }

    /// Individually-tracked projections of `preferences`, kept in sync by the conformance.
    ///
    /// A view that reads `savedCountryCodes` invalidates when saved countries change and stays
    /// put when a trip changes.
    var savedCountryCodes: [String] { get }
    var trips: [Trip] { get }
    var favoriteWidgetCountryCode: String? { get }
    var homeCountryCode: String { get }
    /// The one trip the widgets and Siri talk about, derived from `trips`.
    var currentTrip: Trip? { get }

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

            projectObservableValues()
            persist()
        }
    }

    // The fields of `preferences`, re-published as individual observable properties so readers
    // depend on the one they actually use. Each setter short-circuits on an equal value (the
    // `@Observable` macro emits that check because all four types are `Equatable`), so writing a
    // trip doesn't invalidate readers of `savedCountryCodes`.
    private(set) var savedCountryCodes: [String] = []
    private(set) var trips: [Trip] = []
    private(set) var favoriteWidgetCountryCode: String?
    private(set) var homeCountryCode: String = ""

    /// Derived from the `trips` projection rather than from `preferences`, so reading it doesn't
    /// drag in the rest of the blob. Not cached: it depends on today's date as much as on the
    /// trips themselves, so a stored value would go stale on its own overnight.
    var currentTrip: Trip? {
        TravelPreferences.currentTrip(among: trips)
    }

    private func projectObservableValues() {
        savedCountryCodes = preferences.savedCountryCodes
        trips = preferences.trips
        favoriteWidgetCountryCode = preferences.favoriteWidgetCountryCode
        homeCountryCode = preferences.homeCountryCode
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

        // `projectObservableValues()` is called explicitly here because `didSet` does not fire for
        // assignments made inside `init` — without it the projections would stay empty until the
        // first write.
        if let inMemoryPreferences {
            self.preferences = inMemoryPreferences
            projectObservableValues()
            mirrorWidgetValues()
            return
        }

        iCloudStore.synchronize()
        self.preferences = Self.loadPreferences(from: iCloudStore)
        projectObservableValues()
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
        // Reads the projection, not `preferences`: this one *is* called from view bodies (the
        // country-detail star, the list rows), so going through the blob would make those screens
        // invalidate on every trip and device edit.
        savedCountryCodes.contains(Self.normalizedCountryCode(code))
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
        let currentTrip = currentTrip
        appGroupDefaults.set(favoriteWidgetCountryCode, forKey: AppGroup.favoriteCountryCodeKey)
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

/// No-op fallback for the `@Entry` default value. Stateless — `preferences` is computed and
/// discards writes — so the type is `Sendable` and a single instance can live in a `static let`
/// (see the environment entry at the bottom of this file).
final class NullTravelPreferencesStore: TravelPreferencesStoring, Sendable {
    @MainActor var preferences: TravelPreferences {
        get { TravelPreferences() }
        set {}
    }

    @MainActor var savedCountryCodes: [String] { [] }
    @MainActor var trips: [Trip] { [] }
    @MainActor var favoriteWidgetCountryCode: String? { nil }
    @MainActor var homeCountryCode: String { "" }
    @MainActor var currentTrip: Trip? { nil }

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
    /// Projected the same way the real store does it, rather than exposing the fields as computed
    /// properties over `preferences` — otherwise previews and tests would observe a coarser
    /// dependency graph than the app does, which is exactly the bug the projections fix.
    var preferences: TravelPreferences {
        didSet {
            guard preferences != oldValue else {
                return
            }

            projectObservableValues()
        }
    }

    private(set) var savedCountryCodes: [String] = []
    private(set) var trips: [Trip] = []
    private(set) var favoriteWidgetCountryCode: String?
    private(set) var homeCountryCode: String = ""

    var currentTrip: Trip? {
        TravelPreferences.currentTrip(among: trips)
    }

    init(preferences: TravelPreferences = TravelPreferences()) {
        self.preferences = preferences
        projectObservableValues()
    }

    private func projectObservableValues() {
        savedCountryCodes = preferences.savedCountryCodes
        trips = preferences.trips
        favoriteWidgetCountryCode = preferences.favoriteWidgetCountryCode
        homeCountryCode = preferences.homeCountryCode
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
    /// Backed by a `static let`: `@Entry` wraps its default in a computed getter, so an inline
    /// `NullTravelPreferencesStore()` would allocate a fresh instance on every fallback read and
    /// make every falling-back reader invalidate on unrelated environment writes. Latent today
    /// (the app root injects the real store), kept as a regression guard.
    @Entry var travelPreferencesStore: any TravelPreferencesStoring = defaultTravelPreferencesStore

    private static let defaultTravelPreferencesStore = NullTravelPreferencesStore()
}
