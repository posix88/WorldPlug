import SwiftUI
import Repository_iOS
import ComposableArchitecture
import SwiftData

public struct CountriesListView: View {
    @Bindable var store: StoreOf<CountriesListFeature>
    @Query(sort: \Country.name) private var countries: [Country]

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.filteredCountries) { country in
                        CountryCard(country: country, selectedPlug: $store.selectedPlug.sending(\.openPlugDetail))
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(WorldPlugAsset.Assets.background.swiftUIColor)
            .scrollContentBackground(.hidden)
            .searchable(text: $store.searchQuery.sending(\.searchQueryChanged))
            .onAppear {
                store.send(.viewLoaded(countries: countries))
            }
            .navigationTitle("Pluggy")
        }
    destination: { store in
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
            Plug(id: "D", name: "Type B", shortInfo: "short info", info: "info", images: [])
        ]
    }

    return CountriesListView(
        store: Store(initialState: CountriesListFeature.State()) {
            CountriesListFeature()
        }
    ).modelContainer(container)
}
#endif
