import SwiftUI
import Repository
import ComposableArchitecture
import SwiftData

public struct CountriesListView: View {
    @Bindable var store: StoreOf<CountriesListFeature>
    @Query(sort: \Country.name) private var countries: [Country]

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                LazyVStack(spacing: .lg) {
                    // Enhanced header section when there are countries
                    if !store.filteredCountries.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: .xs) {
                                Text(LocalizationKeys.countriesTitle.localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.textRegular)
                                
                                Text(LocalizationKeys.countriesAvailable.localized(store.filteredCountries.count))
                                    .font(.subheadline)
                                    .foregroundStyle(.textLight)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, .xxl)
                        .padding(.top, .md)
                        .padding(.bottom, .lg)
                    }
                    
                    // Countries list
                    ForEach(store.filteredCountries) { country in
                        CountryCard(country: country, selectedPlug: $store.selectedPlug.sending(\.openPlugDetail))
                    }
                    
                    // Empty state
                    if store.filteredCountries.isEmpty && !store.searchQuery.isEmpty {
                        ContentUnavailableView.search(text: store.searchQuery)
                            .padding(.top, .special)
                    }
                }
                .padding(.horizontal, .xxl)
                .padding(.bottom, .xxl)
            }
            .background(.backgroundSurface)
            .scrollContentBackground(.hidden)
            .searchable(
                text: $store.searchQuery.sending(\.searchQueryChanged),
                prompt: Text(LocalizationKeys.searchCountriesPlaceholder.localized)
            )
            .onAppear {
                store.send(.viewLoaded(countries: countries))
            }
            .navigationTitle(LocalizationKeys.appTitle.localized)
            .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .countryDetail(let store):
                CountryDetailView(store: store)

            case .plugDetail(let store):
                PlugDetailView(store: store)
            }
        }
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    for i in ["AF", "IT", "GB", "FO", "GU"] {
        let country = Country(code: "\(i)", voltage: "230V", frequency: "50Hz", flagUnicode: "🏴‍☠️")
        container.mainContext.insert(country)
        country.plugs = [
            Plug(id: "A", name: "Type A", shortInfo: "short info", info: "info", images: []),
            Plug(id: "B", name: "Type B", shortInfo: "short info", info: "info", images: []),
            Plug(id: "C", name: "Type B", shortInfo: "short info", info: "info", images: []),
            Plug(id: "D", name: "Type B", shortInfo: "short info", info: "info", images: []),
        ]
    }

    return CountriesListView(
        store: Store(initialState: CountriesListFeature.State()) {
            CountriesListFeature()
        }
    ).modelContainer(container)
}
#endif
