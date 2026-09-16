import Repository
import SwiftUI

// MARK: - WatchRootView

struct WatchRootView: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        NavigationStack {
            if let loadError = catalog.loadError {
                ContentUnavailableView(
                    "watch.countries.unavailable.title",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if catalog.countries.isEmpty {
                ProgressView()
            } else {
                List {
                    WatchMainNavigationSection(
                        catalog: catalog,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
                .navigationTitle("watch.app.title")
            }
        }
        .task(id: locale.identifier) {
            catalog.load(locale: locale)
        }
    }
}

// MARK: - WatchMainNavigationSection

private struct WatchMainNavigationSection: View {
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Section {
            NavigationLink {
                WatchSavedCountriesView(
                    catalog: catalog,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            } label: {
                Label("watch.saved.title", systemImage: "star")
            }

            NavigationLink {
                WatchHomeCountryView(
                    catalog: catalog,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            } label: {
                Label("watch.home.country", systemImage: "house")
            }

            NavigationLink {
                WatchCountriesListView(
                    countries: catalog.countries,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            } label: {
                Label("watch.countries.title", systemImage: "globe")
            }
        }
    }
}

#Preview("App Home") {
    WatchRootView(
        catalog: WatchPreviewFixtures.catalog(),
        preferencesStore: WatchPreviewFixtures.preferences(),
        premiumEntitlement: WatchPreviewFixtures.premium()
    )
}
