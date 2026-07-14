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

            SavedCountriesView()
                .tabItem {
                    Label(LocalizationKeys.savedCountriesTitle.localized, systemImage: "star.fill")
                }
                .tag(1)
        }
        .onChange(of: deepLinkedCountryCode) { _, countryCode in
            if countryCode != nil {
                selectedTab = 0
            }
        }
    }
}
