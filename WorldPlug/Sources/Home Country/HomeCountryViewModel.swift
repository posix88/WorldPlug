import Foundation
import Observation
import Repository
import SwiftData

// MARK: - HomeCountryViewModel

/// Shared observable that owns all home-country state.
/// Owned at the app root and injected via SwiftUI `.environment()`.
@Observable
@MainActor
final class HomeCountryViewModel: HomeCountryViewModelType {
    private var store: any HomeCountryStoring
    private let modelContext: ModelContext

    var homeCountryCode: String

    var homeCountry: Country? {
        let code = homeCountryCode
        guard !code.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<Country>(
            predicate: #Predicate { $0.code == code }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    var homePlugTypeIDs: Set<String> {
        Set(homeCountry?.plugs.map(\.id) ?? [])
    }

    init(
        store: some HomeCountryStoring = UserDefaultsHomeCountryStore(),
        modelContext: ModelContext
    ) {
        self.store = store
        self.modelContext = modelContext
        self.homeCountryCode = Self.normalizedCountryCode(store.homeCountryCode)
    }

    func setHome(code: String) {
        let normalizedCode = Self.normalizedCountryCode(code)
        homeCountryCode = normalizedCode
        store.homeCountryCode = normalizedCode
    }

    func clearHome() {
        homeCountryCode = ""
        store.homeCountryCode = ""
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

        let homePlugTypeIDs = Set(home.plugs.map(\.id))
        return homePlugTypeIDs.contains(plug.id) ? .compatible : .adapterNeeded
    }

    private static func normalizedCountryCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
