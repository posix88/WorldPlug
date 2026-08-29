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
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.countries) {
                CountriesListView(
                    modelContext: modelContext,
                    homeCountryViewModel: homeCountryViewModel,
                    travelPreferencesStore: travelPreferencesStore,
                    premiumEntitlement: premiumEntitlement,
                    analyticsTracker: analyticsTracker,
                    deepLinkedCountryCode: $deepLinkedCountryCode
                )
            } label: {
                Label(LocalizationKeys.countriesTitle.localized, systemImage: "globe.europe.africa.fill")
                    .accessibilityIdentifier("tab.countries")
            }

            Tab(value: AppTab.tripCheck) {
                TripCheckView(
                    travelPreferencesStore: travelPreferencesStore,
                    homeCountryViewModel: homeCountryViewModel,
                    premiumEntitlement: premiumEntitlement,
                    analyticsTracker: analyticsTracker
                )
            } label: {
                Label(LocalizationKeys.tripCheckTabTitle.localized, systemImage: "suitcase.rolling.fill")
                    .accessibilityIdentifier("tab.tripCheck")
            }

            Tab(value: AppTab.saved) {
                SavedCountriesView(
                    premiumEntitlement: premiumEntitlement,
                    travelPreferencesStore: travelPreferencesStore,
                    homeCountryViewModel: homeCountryViewModel,
                    analyticsTracker: analyticsTracker
                )
            } label: {
                Label(LocalizationKeys.savedCountriesTitle.localized, systemImage: "star.fill")
                    .accessibilityIdentifier("tab.saved")
            }
        }
        .tint(.voltTint)
        .onAppIntentExecution(OpenCountryIntent.self) { intent in
            selectedTab = .countries
            deepLinkedCountryCode = intent.target.id
        }
    }
}

#if DEBUG
#Preview {
    RootTabView(
        modelContext: Repository.sharedModelContainer.mainContext,
        deepLinkedCountryCode: .constant(nil),
        selectedTab: .constant(.countries)
    )
    .modelContainer(Repository.sharedModelContainer)
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
    .environment(\.travelPreferencesStore, PreviewTravelPreferencesStore())
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
