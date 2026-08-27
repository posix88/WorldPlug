import Analytics
import AppIntents
import Repository
import SwiftData
import SwiftUI

// MARK: - RootTabView

struct RootTabView: View {
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.analyticsTracker) private var analyticsTracker
    let modelContext: ModelContext
    @Binding var deepLinkedCountryCode: String?
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            CountriesListView(
                modelContext: modelContext,
                homeCountryViewModel: homeCountryViewModel,
                travelPreferencesStore: travelPreferencesStore,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker,
                deepLinkedCountryCode: $deepLinkedCountryCode
            )
            .tabItem {
                Label(LocalizationKeys.countriesTitle.localized, systemImage: "globe.europe.africa.fill")
            }
            .tag(0)
            .accessibilityIdentifier("tab.countries")

            TripCheckView(
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker
            )
            .tabItem {
                Label(LocalizationKeys.tripCheckTabTitle.localized, systemImage: "suitcase.rolling.fill")
            }
            .tag(1)
            .accessibilityIdentifier("tab.tripCheck")

            SavedCountriesView(
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                analyticsTracker: analyticsTracker
            )
            .tabItem {
                Label(LocalizationKeys.savedCountriesTitle.localized, systemImage: "star.fill")
            }
            .tag(2)
            .accessibilityIdentifier("tab.saved")
        }
        .tint(.voltTint)
        .onAppIntentExecution(OpenCountryIntent.self) { intent in
            selectedTab = 0
            deepLinkedCountryCode = intent.target.id
        }
    }
}

#if DEBUG
#Preview {
    RootTabView(
        modelContext: Repository.sharedModelContainer.mainContext,
        deepLinkedCountryCode: .constant(nil),
        selectedTab: .constant(0)
    )
    .modelContainer(Repository.sharedModelContainer)
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
    .environment(\.travelPreferencesStore, PreviewTravelPreferencesStore())
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
