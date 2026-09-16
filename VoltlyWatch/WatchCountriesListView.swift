import Repository
import SwiftUI

// MARK: - WatchCountriesListView

struct WatchCountriesListView: View {
    let countries: [CountrySnapshot]
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    @State private var model: WatchCountriesListModel

    init(
        countries: [CountrySnapshot],
        preferencesStore: WatchTravelPreferencesStore,
        premiumEntitlement: WatchPremiumEntitlement
    ) {
        self.countries = countries
        self.preferencesStore = preferencesStore
        self.premiumEntitlement = premiumEntitlement
        _model = State(initialValue: WatchCountriesListModel(countries: countries))
    }

    var body: some View {
        @Bindable var model = model

        List {
            if !model.searchQuery.isEmpty {
                Button {
                    model.searchQuery = ""
                } label: {
                    Label("watch.search.clear", systemImage: "xmark.circle")
                }
            }

            ForEach(model.filteredCountries, id: \.code) { country in
                WatchCountryNavigationLink(
                    country: country,
                    preferencesStore: preferencesStore,
                    premiumEntitlement: premiumEntitlement
                )
            }
        }
        .navigationTitle("watch.countries.title")
        .searchable(text: $model.searchQuery, prompt: "watch.search.country.placeholder")
        .onChange(of: countries) { _, countries in
            model.replaceCountries(with: countries)
        }
    }
}

#Preview("All Countries") {
    NavigationStack {
        WatchCountriesListView(
            countries: WatchPreviewFixtures.catalog().countries,
            preferencesStore: WatchPreviewFixtures.preferences(),
            premiumEntitlement: WatchPreviewFixtures.premium()
        )
    }
}
