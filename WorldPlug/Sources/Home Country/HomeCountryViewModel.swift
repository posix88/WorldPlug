import Observation
import Repository
import SwiftData

// MARK: - HomeCountryViewModel

/// Shared observable that owns all home-country state.
/// Owned at the app root and injected via SwiftUI `.environment()`.
@Observable
@MainActor
final class HomeCountryViewModel {
    private var store: any HomeCountryStoring
    private let modelContext: ModelContext

    var homeCountryCode: String

    var homeCountry: Country? {
        guard !homeCountryCode.isEmpty else { return nil }
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
}
