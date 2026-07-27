import Analytics
import Repository
import SwiftData
import SwiftUI

// MARK: - RootTabView

struct RootTabView: View {
    let modelContext: ModelContext
    @Binding var deepLinkedCountryCode: String?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CountriesListView(
                modelContext: modelContext,
                deepLinkedCountryCode: $deepLinkedCountryCode
            )
                .tabItem {
                    Label(LocalizationKeys.countriesTitle.localized, systemImage: "globe.europe.africa.fill")
                }
                .tag(0)

            TripCheckView()
                .tabItem {
                    Label(LocalizationKeys.tripCheckTabTitle.localized, systemImage: "suitcase.rolling.fill")
                }
                .tag(1)

            SavedCountriesView()
                .tabItem {
                    Label(LocalizationKeys.savedCountriesTitle.localized, systemImage: "star.fill")
                }
                .tag(2)
        }
        .onChange(of: deepLinkedCountryCode) { _, countryCode in
            if countryCode != nil {
                selectedTab = 0
            }
        }
        .tint(.voltTint)
    }
}

#if DEBUG
#Preview {
    RootTabView(
        modelContext: Repository.sharedModelContainer.mainContext,
        deepLinkedCountryCode: .constant(nil)
    )
    .modelContainer(Repository.sharedModelContainer)
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
    .environment(\.travelPreferencesStore, PreviewTravelPreferencesStore())
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
