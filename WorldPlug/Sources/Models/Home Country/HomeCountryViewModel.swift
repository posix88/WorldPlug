import Analytics
import Foundation
import Observation
import Repository
import SwiftData
import WidgetKit

// MARK: - HomeCountryViewModel

/// Shared observable that owns all home-country state.
/// Owned at the app root and injected via SwiftUI `.environment()`.
@Observable
@MainActor
final class HomeCountryViewModel: HomeCountryViewModelType {
    private var store: any HomeCountryStoring
    private var travelPreferencesStore: any TravelPreferencesStoring
    private let modelContext: ModelContext
    private let analyticsTracker: any AnalyticsTracker
    private let launchHomeCountryCode: String?

    var homeCountryCode: String
    private(set) var homeCountry: Country?
    private(set) var homePlugTypeIDs: Set<String>

    init(
        store: some HomeCountryStoring = UserDefaultsHomeCountryStore(),
        travelPreferencesStore: some TravelPreferencesStoring = ICloudTravelPreferencesStore(),
        analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker(),
        launchHomeCountryCode: String? = nil,
        modelContext: ModelContext
    ) {
        self.store = store
        self.travelPreferencesStore = travelPreferencesStore
        self.analyticsTracker = analyticsTracker
        self.launchHomeCountryCode = launchHomeCountryCode.map(Self.normalizedCountryCode)
        self.modelContext = modelContext
        let countryCode = Self.initialHomeCountryCode(
            from: store,
            travelPreferencesStore: travelPreferencesStore,
            preferredCountryCode: launchHomeCountryCode
        )
        let country = Self.country(for: countryCode, in: modelContext)
        self.homeCountryCode = countryCode
        self.homeCountry = country
        self.homePlugTypeIDs = Set(country?.plugs.map(\.id) ?? [])
    }

    func setHome(code: String) {
        let normalizedCode = Self.normalizedCountryCode(code)
        let codeChanged = normalizedCode != homeCountryCode
        guard codeChanged || (!normalizedCode.isEmpty && homeCountry?.code != normalizedCode) else {
            return
        }

        updateHomeCountry(with: normalizedCode)
        if codeChanged {
            analyticsTracker.track(.homeCountrySet)
        }
    }

    func clearHome() {
        guard !homeCountryCode.isEmpty else {
            return
        }

        updateHomeCountry(with: "")
        analyticsTracker.track(.homeCountryCleared)
    }

    func refreshHomeCountry() {
        guard launchHomeCountryCode == nil else {
            return
        }

        travelPreferencesStore.reloadFromICloud()
        let countryCode = Self.normalizedCountryCode(travelPreferencesStore.preferences.homeCountryCode)
        guard countryCode != homeCountryCode || (!countryCode.isEmpty && homeCountry?.code != countryCode) else {
            return
        }

        updateHomeCountry(with: countryCode)
    }

    func plugCompatibility(for plug: Plug, in country: Country) -> PlugCompatibility {
        guard !homeCountryCode.isEmpty, country.code != homeCountryCode else {
            return .compatible
        }
        guard let home = homeCountry else {
            return .compatible
        }
        guard VoltageCompatibility.isCompatible(home.voltage, country.voltage) else {
            return .converterRequired
        }

        return homePlugTypeIDs.contains(plug.id) ? .compatible : .adapterNeeded
    }

    private func updateHomeCountry(with countryCode: String) {
        homeCountryCode = countryCode
        homeCountry = Self.country(for: countryCode, in: modelContext)
        homePlugTypeIDs = Set(homeCountry?.plugs.map(\.id) ?? [])
        store.homeCountryCode = countryCode

        var preferences = travelPreferencesStore.preferences
        preferences.homeCountryCode = countryCode
        travelPreferencesStore.preferences = preferences

        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func initialHomeCountryCode(
        from store: some HomeCountryStoring,
        travelPreferencesStore: some TravelPreferencesStoring,
        preferredCountryCode: String?
    ) -> String {
        var preferences = travelPreferencesStore.preferences
        let preferredCountryCode = Self.normalizedCountryCode(preferredCountryCode ?? "")
        if !preferredCountryCode.isEmpty {
            store.homeCountryCode = preferredCountryCode
            preferences.homeCountryCode = preferredCountryCode
            travelPreferencesStore.preferences = preferences
            return preferredCountryCode
        }

        let iCloudCountryCode = Self.normalizedCountryCode(preferences.homeCountryCode)

        if !iCloudCountryCode.isEmpty {
            store.homeCountryCode = iCloudCountryCode
            return iCloudCountryCode
        }

        let legacyCountryCode = Self.normalizedCountryCode(store.homeCountryCode)
        guard !legacyCountryCode.isEmpty else {
            return ""
        }

        preferences.homeCountryCode = legacyCountryCode
        travelPreferencesStore.preferences = preferences
        return legacyCountryCode
    }
}

private extension HomeCountryViewModel {
    static func country(for code: String, in modelContext: ModelContext) -> Country? {
        guard !code.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<Country>(
            predicate: #Predicate { $0.code == code }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    static func normalizedCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
