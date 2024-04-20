import SwiftUI
import Repository_iOS
import ComposableArchitecture

struct CountryDetailView: View {
    var store: StoreOf<CountryDetailFeature>

    var body: some View {
        List(store.country.sortedPlugs) { plug in
                NavigationLink(state: CountriesListFeature.Path.State.plugDetail(PlugDetailFeature.State(plug: plug))) {
                    HStack {
                        Image(systemName: plug.plugSymbol)
                            .imageScale(.large)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(plug.name)
                                .font(.callout)
                                .bold()

                            Text(plug.info)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowSeparator(.hidden, edges: .all)
                .listSectionSeparator(.hidden, edges: .all)
        }
        .background(WorldPlugAsset.Assets.background.swiftUIColor)
        .scrollContentBackground(.hidden)
        .navigationTitle(store.country.name)
    }
}


#if DEBUG
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🏴‍☠️")
    container.mainContext.insert(country)
    country.plugs = [
        Plug(id: "A", name: "Type A", info: "info", images: [URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_plug_l.png")!]),
        Plug(id: "B", name: "Type B", info: "info", images: [URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_plug_l.png")!])
    ]

    return NavigationStack {
        CountryDetailView(store:
                            Store(initialState:
                                    CountryDetailFeature.State(country: country), reducer: {
                CountryDetailFeature()
        }))
    }
}
#endif
