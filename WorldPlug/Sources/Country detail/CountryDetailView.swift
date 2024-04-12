import SwiftUI
import Repository_iOS
import ComposableArchitecture

struct CountryDetailView: View {
    var store: StoreOf<CountryDetailFeature>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [ GridItem(.flexible()), GridItem(.flexible())] ){
                ForEach(store.country.sortedPlugs) { plug in
                    VStack {
                        AsyncImage(url: plug.images.first) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } placeholder: {
                            VStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .clipped()
                                    .foregroundStyle(WorldPlugAsset.Assets.background.swiftUIColor)
                            }
                            .frame(width: 50, height: 50)
                            .background(WorldPlugAsset.Assets.textLighter.swiftUIColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        HStack {
                            Image(systemName: plug.plugSymbol)
                                .imageScale(.large)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(plug.name)
                                    .font(.body)
                                    .bold()
                                    .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .embedInCard()
                }
            }
            .padding()
        }
        .background(WorldPlugAsset.Assets.background.swiftUIColor)
        .scrollBounceBehavior(.basedOnSize)
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
