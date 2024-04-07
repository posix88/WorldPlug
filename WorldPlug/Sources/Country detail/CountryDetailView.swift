import SwiftUI
import Repository_iOS
import ComposableArchitecture

struct CountryDetailView: View {
    @Bindable var store: StoreOf<CountryDetailFeature>

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(store.plugs) { plug in
                    HStack(alignment: .top) {
                        AsyncImage(url: plug.images.first) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                        } placeholder: {
                            VStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipped()
                            }
                            .frame(width: 150, height: 150)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(plug.name)
                                .font(.headline)

                            Text(plug.info)
                                .lineLimit(3)
                                .font(.caption2)

                            Spacer()
                            
                            HStack {
                                Button {

                                } label: {
                                    Text("See more")
                                        .font(.caption)
                                        .padding(.all, 8)
                                }
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(100)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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

public extension View {
    @ViewBuilder
    /// Embed the current View in a `Card` style background.
    /// - Parameter color: the background color
    /// - Parameter radius: the card corner radius
    /// - Parameter insets: the insets to be applied to the card view content
    /// - Parameter borderColor: the card border color
    /// - Parameter border: the card border tickness
    func embedInCard(
        _ color: Color = WorldPlugAsset.Assets.card.swiftUIColor,
        radius: CGFloat = 10,
        insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
        borderColor: Color = WorldPlugAsset.Assets.border.swiftUIColor,
        border: CGFloat = 1,
        action: (() -> Void)? = nil
    ) -> some View {
        padding(insets)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: border)
                    .fill(color)
            }
    }
}

#Preview {
    CountryDetailView(store:
                        Store(initialState:
                                CountryDetailFeature.State(country:
                                                            Country(
                                                                code: "IT",
                                                                voltage: "",
                                                                frequency: "",
                                                                flagUnicode: "",
                                                                plugTypes: []
                                                            ),
                                                           plugs: [
                                                            Plug(id: "1",
                                                                 name: "A",
                                                                 info: "info info",
                                                                 images: [
                                                                    URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_plug_l.png")!
                                                                 ]
                                                                ),
                                                            Plug(id: "2",
                                                                 name: "B",
                                                                 info: "info info",
                                                                 images: [
                                                                    URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs")!
                                                                 ]
                                                                )
                                                           ]
                                                          ), reducer: {
       // CountryDetailFeature()
    }))
}
