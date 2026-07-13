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
    private let modelContext: ModelContext

    var homeCountryCode: String
    private(set) var homeCountry: Country?
    private(set) var homePlugTypeIDs: Set<String>

    init(
        store: some HomeCountryStoring = UserDefaultsHomeCountryStore(),
        modelContext: ModelContext
    ) {
        self.store = store
        self.modelContext = modelContext
        let countryCode = Self.normalizedCountryCode(store.homeCountryCode)
        let country = Self.country(for: countryCode, in: modelContext)
        self.homeCountryCode = countryCode
        self.homeCountry = country
        self.homePlugTypeIDs = Set(country?.plugs.map(\.id) ?? [])
    }

    func setHome(code: String) {
        let normalizedCode = Self.normalizedCountryCode(code)
        homeCountryCode = normalizedCode
        homeCountry = Self.country(for: normalizedCode, in: modelContext)
        homePlugTypeIDs = Set(homeCountry?.plugs.map(\.id) ?? [])
        store.homeCountryCode = normalizedCode
        WidgetCenter.shared.reloadAllTimelines()
    }

    func clearHome() {
        homeCountryCode = ""
        homeCountry = nil
        homePlugTypeIDs = []
        store.homeCountryCode = ""
        WidgetCenter.shared.reloadAllTimelines()
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

    private static func country(for code: String, in modelContext: ModelContext) -> Country? {
        guard !code.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<Country>(
            predicate: #Predicate { $0.code == code }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private static func normalizedCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
