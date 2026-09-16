import Repository
import SwiftUI

// MARK: - WatchHomeCountryView

struct WatchHomeCountryView: View {
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        List {
            WatchHomeCountrySection(
                country: catalog.country(withCode: preferencesStore.homeCountryCode),
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
            if preferencesStore.homeCountryCode.isEmpty {
                WatchBrowseCountriesSection(
                    countries: catalog.countries,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            }
        }
        .navigationTitle("watch.home.title")
    }
}

// MARK: - WatchHomeCountrySection

private struct WatchHomeCountrySection: View {
    let country: CountrySnapshot?
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Section {
            if let country {
                WatchCountryNavigationLink(
                    country: country,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            } else {
                Text("watch.home.empty")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("watch.home.section")
        }
    }
}

// MARK: - WatchBrowseCountriesSection

private struct WatchBrowseCountriesSection: View {
    let countries: [CountrySnapshot]
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Section {
            NavigationLink {
                WatchCountriesListView(
                    countries: countries,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            } label: {
                Label("watch.countries.browse", systemImage: "globe")
            }
        }
    }
}

#Preview("Home Country") {
    NavigationStack {
        WatchHomeCountryView(
            catalog: WatchPreviewFixtures.catalog(),
            preferencesStore: WatchPreviewFixtures.preferences(),
            premiumEntitlement: WatchPreviewFixtures.premium()
        )
    }
}
