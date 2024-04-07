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
                NavigationLink(state: CountryDetailFeature.State(country: country)) {
                    HStack {
                        Text(country.flagUnicode)
                            .font(.system(size: 30))
                        VStack(alignment: .leading) {
                            Text(country.name)
                                .font(.headline)
                            Text("Plug types: " + country.plugTypes.joined(separator: " • "))
                                .font(.caption)
                        }
                    }
                }.buttonStyle(.borderless)
            }
            .background(WorldPlugAsset.Assets.background.swiftUIColor)
            .scrollContentBackground(.hidden)
            .searchable(text: $store.searchQuery.sending(\.searchQueryChanged))
            .onAppear {
                store.send(.viewLoaded(countries: countries))
            }
            .navigationTitle("World plugs")
        }
        destination: { store in
            CountryDetailView(store: store)
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    for i in ["AF", "IT", "GB", "FO", "GU"] {
        let user = Country(code: "\(i)", voltage: "", frequency: "", flagUnicode: "🏴‍☠️", plugTypes: ["A", "B", "C"])
        container.mainContext.insert(user)
    }

    return CountriesListView(
        store: Store(initialState: CountriesListFeature.State()) {
            CountriesListFeature()
        }
    ).modelContainer(container)
}
