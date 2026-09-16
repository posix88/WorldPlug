import Foundation
import Observation
import Repository

// MARK: - WatchTravelPreferencesStore

/// Watch-side projection of the same iCloud preferences blob the iPhone app owns.
@Observable
@MainActor
final class WatchTravelPreferencesStore {
    @ObservationIgnored private let iCloudStore: NSUbiquitousKeyValueStore
    @ObservationIgnored private let persistsChanges: Bool
    @ObservationIgnored private nonisolated(unsafe) var externalChangeObserver: NSObjectProtocol?
    @ObservationIgnored private var preferences: TravelPreferences
    @ObservationIgnored private lazy var connectivitySync = WatchPreferencesConnectivitySync { [weak self] preferences in
        self?.replace(with: preferences, persist: false)
    }

    private(set) var savedCountryCodes: [String] = []
    private(set) var homeCountryCode = ""

    init(iCloudStore: NSUbiquitousKeyValueStore = .default) {
        self.iCloudStore = iCloudStore
        self.persistsChanges = true
        self.preferences = TravelPreferencesStorage.load(from: iCloudStore)
        publishPreferences()
        observeExternalChanges()
        connectivitySync.activate()
    }

    init(previewPreferences: TravelPreferences) {
        self.iCloudStore = .default
        self.persistsChanges = false
        self.preferences = previewPreferences
        publishPreferences()
    }

    deinit {
        if let externalChangeObserver {
            NotificationCenter.default.removeObserver(externalChangeObserver)
        }
    }

    func reloadFromICloud() {
        guard persistsChanges else {
            return
        }
        replace(with: TravelPreferencesStorage.load(from: iCloudStore), persist: false)
    }

    func isSaved(countryCode: String) -> Bool {
        savedCountryCodes.contains(Self.normalized(countryCode))
    }

    func toggleSaved(countryCode: String) {
        let countryCode = Self.normalized(countryCode)
        guard !countryCode.isEmpty else {
            return
        }

        var updated = preferences
        if let index = updated.savedCountryCodes.firstIndex(of: countryCode) {
            updated.savedCountryCodes.remove(at: index)
        } else {
            updated.savedCountryCodes.append(countryCode)
        }
        replace(with: updated, persist: true)
    }

    func setHome(countryCode: String) {
        var updated = preferences
        updated.homeCountryCode = Self.normalized(countryCode)
        replace(with: updated, persist: true)
    }

    func clearHome() {
        setHome(countryCode: "")
    }

    private func observeExternalChanges() {
        externalChangeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromICloud()
            }
        }
    }

    private func replace(with updatedPreferences: TravelPreferences, persist: Bool) {
        guard updatedPreferences != preferences else {
            return
        }

        preferences = updatedPreferences
        publishPreferences()
        if persist, persistsChanges {
            TravelPreferencesStorage.persist(updatedPreferences, to: iCloudStore)
            connectivitySync.publish(updatedPreferences)
        }
    }

    private func publishPreferences() {
        savedCountryCodes = preferences.savedCountryCodes
        homeCountryCode = preferences.homeCountryCode
    }

    private static func normalized(_ countryCode: String) -> String {
        countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
