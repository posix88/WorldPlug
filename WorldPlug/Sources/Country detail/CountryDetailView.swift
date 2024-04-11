import SwiftUI
import Repository_iOS
import ComposableArchitecture

struct CountryDetailView: View {
    @Bindable var store: StoreOf<CountryDetailFeature>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [ GridItem(.flexible()), GridItem(.flexible())] ){
                ForEach(store.plugs) { plug in
                    HStack {
//                        AsyncImage(url: plug.images.first) { image in
//                            image
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 50, height: 50)
//                                .clipped()
//                                .clipShape(RoundedRectangle(cornerRadius: 8))
//
//                        } placeholder: {
//                            VStack {
//                                Image(systemName: "photo")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 25, height: 25)
//                                    .clipped()
//                                    .foregroundStyle(WorldPlugAsset.Assets.background.swiftUIColor)
//                            }
//                            .frame(width: 50, height: 50)
//                            .background(WorldPlugAsset.Assets.textLighter.swiftUIColor)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                        }

//                        Image(uiImage: plug.plugSymbol!)
//                            .resizable()
//                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(plug.name)
                                .font(.title2)
                                .bold()
                                .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                        }
                    }
                    .embedInCard()
                }
            }
            .padding()
        }
        .background(WorldPlugAsset.Assets.background.swiftUIColor)
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(store.country.name)
        .onAppear {
            store.send(.viewLoaded)
        }
    }
}



#Preview {
    NavigationStack {
        CountryDetailView(store:
                            Store(initialState:
                                    CountryDetailFeature.State(country:
                                                                Country(
                                                                    code: "IT",
                                                                    voltage: "220 V",
                                                                    frequency: "50 Hz",
                                                                    flagUnicode: ""
                                                              )), reducer: {
        }))
    }
}
