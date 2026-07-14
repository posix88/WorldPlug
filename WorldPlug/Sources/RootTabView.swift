import SwiftData
import SwiftUI

// MARK: - RootTabView

struct RootTabView: View {
    let modelContext: ModelContext

    var body: some View {
        TabView {
            CountriesListView(modelContext: modelContext)
                .tabItem {
                    Label(LocalizationKeys.countriesTitle.localized, systemImage: "globe.europe.africa.fill")
                }

            SavedCountriesView()
                .tabItem {
                    Label(LocalizationKeys.savedCountriesTitle.localized, systemImage: "star.fill")
                }
        }
    }
}
