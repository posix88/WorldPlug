import SwiftUI
import Repository_iOS
import ComposableArchitecture
import SwiftData

public struct CountriesListView: View {
    @Bindable var store: StoreOf<CountriesListFeature>
    @State private var searchText = ""
    @Query(sort: \Country.name) private var countries: [Country]

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List(store.filteredCountries) { country in
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(country.flagUnicode)
                                .font(.system(size: 30))

                            Text(country.name)
                                .font(.headline)
                                .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                        }
                        .padding(.bottom, 8)

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.circle")
                                    .imageScale(.medium)

                                Text(country.voltage)
                                    .font(.caption)
                            }
                            .foregroundStyle(WorldPlugAsset.Assets.volt.swiftUIColor)

                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .imageScale(.medium)

                                Text(country.frequency)
                                    .font(.caption)
                            }
                            .foregroundStyle(WorldPlugAsset.Assets.frequency.swiftUIColor)
                        }
                        .padding(.bottom, 16)


                        HStack {
                            ForEach(country.sortedPlugs) { plug in
                                HStack(spacing: 8) {
                                    Image(systemName: plug.plugSymbol)
                                        .imageScale(.small)

                                    Text(plug.id)
                                        .font(.caption2)
                                        .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                                }
                                .padding(.all, 5)
                                .background(WorldPlugAsset.Assets.surfaceSecondary.swiftUIColor)
                                .roundedCornerWithBorder(radius: 8, lineWidth: 1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .embedInCard()

                    NavigationLink(state: CountriesListFeature.Path.State.countryDetail(CountryDetailFeature.State(country: country))) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowSeparator(.hidden, edges: .all)
                .listSectionSeparator(.hidden, edges: .all)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
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


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    for i in ["AF", "IT", "GB", "FO", "GU"] {
        let country = Country(code: "\(i)", voltage: "230V", frequency: "50Hz", flagUnicode: "🏴‍☠️")
        container.mainContext.insert(country)
        country.plugs = [
            Plug(id: "A", name: "Type A", info: "info", images: []),
            Plug(id: "B", name: "Type B", info: "info", images: [])
        ]
    }

    return CountriesListView(
        store: Store(initialState: CountriesListFeature.State()) {
            CountriesListFeature()
        }
    ).modelContainer(container)
}
