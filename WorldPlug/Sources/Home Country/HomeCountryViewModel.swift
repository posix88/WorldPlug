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
        guard !homeCountryCode.isEmpty else {
            return nil
        }

        let descriptor = FetchDescriptor<Country>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.first { $0.code == homeCountryCode }
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
        self.homeCountryCode = store.homeCountryCode
    }

    func setHome(code: String) {
        homeCountryCode = code
        store.homeCountryCode = code
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

        let homeVoltages = parseVoltages(home.voltage)
        let destVoltages = parseVoltages(country.voltage)
        let voltageCompatible = homeVoltages.contains { hv in
            destVoltages.contains { dv in abs(hv - dv) <= 20 }
        }

        guard voltageCompatible else {
            return .converterRequired
        }

        return homePlugTypeIDs.contains(plug.id) ? .compatible : .adapterNeeded
    }

    private func parseVoltages(_ string: String) -> [Int] {
        string.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}
