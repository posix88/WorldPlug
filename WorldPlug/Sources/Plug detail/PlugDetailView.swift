import SwiftUI
import Repository_iOS
import ComposableArchitecture

struct PlugDetailView: View {
    @Bindable var store: StoreOf<PlugDetailFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TabView {
                    ForEach(store.plug.images, id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .tag(url)

                        } placeholder: {
                            VStack {
                                Image(systemName: "photo")
                                    .imageScale(.large)
                                    .tag(url)
                                    .foregroundStyle(WorldPlugAsset.Assets.textLight.swiftUIColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(WorldPlugAsset.Assets.surfaceSecondary.swiftUIColor)
                        }
                        .roundedCorner(radius: 10)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .padding(.horizontal, 16)
                .frame(height: store.viewSize.height * 0.4)

                Text(store.plug.info)
                    .font(.body)
                    .embedInCard()
                    .padding(.horizontal, 16)
            }
        }
        .viewSizeReader($store.viewSize.sending(\.sizeUpdated))
        .background(WorldPlugAsset.Assets.background.swiftUIColor)
        .navigationTitle(store.plug.name)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

#if DEBUG
import SwiftData
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plug.self, configurations: config)
    let plug = Plug(
        id: "A",
        name: "Type A",
        shortInfo: "short info",
        info: "Est ea non incididunt amet proident aliqua mollit sint voluptate. Voluptate dolor ex est minim nulla qui. Occaecat aliquip sint labore anim do. Sint labore eu do officia consectetur. Ea incididunt enim commodo officia ullamco officia sint labore officia labore. Anim est aute eu culpa voluptate tempor dolore labore exercitation mollit non aliquip. Dolore amet sint consectetur eu nulla ullamco elit do enim officia officia reprehenderit ex aliqua elit.",
        images: [
            URL(string: "https://balidave.com/wp-content/uploads/2022/11/best-hotel-bali.jpeg")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_sock_l.png")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_dia_plug_l.png")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_dia_sock_l.png")!
        ]
    )
    container.mainContext.insert(plug)
    return NavigationStack {
        PlugDetailView(store: Store(initialState:
                                        PlugDetailFeature.State(plug: plug), reducer: {
            PlugDetailFeature()
        }))
    }
}
#endif
