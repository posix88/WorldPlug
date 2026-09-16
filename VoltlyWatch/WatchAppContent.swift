import Repository
import SwiftUI

// MARK: - WatchAppContent

struct WatchAppContent: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        if let screen = WatchAppDebugOverrides.screenshotScreen {
            WatchScreenshotScreenView(
                screen: screen,
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        } else {
            WatchRootView(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        }
    }
}

// MARK: - WatchScreenshotScreenView

/// Launch-argument-only destinations for deterministic App Store screenshot capture.
private struct WatchScreenshotScreenView: View {
    let screen: WatchAppDebugOverrides.ScreenshotScreen
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    var body: some View {
        switch screen {
        case .saved:
            WatchSavedScreenshotScreen(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        case .homeCountry:
            WatchHomeCountryScreenshotScreen(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        case .countries:
            WatchCountriesScreenshotScreen(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        case .italy:
            WatchItalyScreenshotScreen(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        }
    }
}

// MARK: - WatchSavedScreenshotScreen

private struct WatchSavedScreenshotScreen: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Group {
            if catalog.countries.isEmpty {
                ProgressView()
            } else {
                NavigationStack {
                    WatchSavedCountriesView(
                        catalog: catalog,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
            }
        }
        .task(id: locale.identifier) {
            catalog.load(locale: locale)
        }
    }
}

// MARK: - WatchHomeCountryScreenshotScreen

private struct WatchHomeCountryScreenshotScreen: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Group {
            if catalog.countries.isEmpty {
                ProgressView()
            } else {
                NavigationStack {
                    WatchHomeCountryView(
                        catalog: catalog,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
            }
        }
        .task(id: locale.identifier) {
            catalog.load(locale: locale)
        }
    }
}

// MARK: - WatchCountriesScreenshotScreen

private struct WatchCountriesScreenshotScreen: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Group {
            if catalog.countries.isEmpty {
                ProgressView()
            } else {
                NavigationStack {
                    WatchCountriesListView(
                        countries: catalog.countries,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
            }
        }
        .task(id: locale.identifier) {
            catalog.load(locale: locale)
        }
    }
}

// MARK: - WatchItalyScreenshotScreen

private struct WatchItalyScreenshotScreen: View {
    @Environment(\.locale) private var locale
    let catalog: WatchCatalogViewModel
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement

    var body: some View {
        Group {
            if let italy = catalog.country(withCode: "IT") {
                NavigationStack {
                    WatchCountryDetailView(
                        country: italy,
                        preferencesStore: preferencesStore,
                        premiumEntitlement: premiumEntitlement
                    )
                }
            } else {
                ProgressView()
            }
        }
        .task(id: locale.identifier) {
            catalog.load(locale: locale)
        }
    }
}
