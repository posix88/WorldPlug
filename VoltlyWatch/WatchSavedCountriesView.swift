import Repository
import SwiftUI

// MARK: - WatchSavedCountriesView

struct WatchSavedCountriesView: View {
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        List {
            WatchSavedCountriesSection(
                countries: preferencesStore.savedCountryCodes.compactMap(catalog.country),
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        }
        .navigationTitle("watch.saved.title")
    }
}

// MARK: - WatchSavedCountriesSection

private struct WatchSavedCountriesSection: View {
    let countries: [CountrySnapshot]
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Section {
            if countries.isEmpty {
                Text("watch.saved.empty")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(countries, id: \.code) { country in
                    WatchCountryNavigationLink(
                        country: country,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
            }
        } header: {
            Text("watch.saved.section")
        }
    }
}

#Preview("Saved Countries") {
    NavigationStack {
        WatchSavedCountriesView(
            catalog: WatchPreviewFixtures.catalog(),
            preferencesStore: WatchPreviewFixtures.preferences(),
            premiumEntitlement: WatchPreviewFixtures.premium()
        )
    }
}
