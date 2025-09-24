import SwiftUI
import Repository
import ComposableArchitecture

struct PlugDetailView: View {
    @Bindable var store: StoreOf<PlugDetailFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: .xl) {
                TabView {
                    ForEach(store.plug.images, id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .tag(url)

                        } placeholder: {
                            VStack {
                                SFSymbols.photo.image
                                .imageScale(.large)
                                .tag(url)
                                .foregroundStyle(Color.textLight)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.surfaceSecondary)
                        }
                        .roundedCorner(radius: 10)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .padding(.horizontal, .xl)
                .frame(height: store.viewSize.height * 0.4)

                Card {
                    Text(store.plug.info)
                        .font(.body)
                        .padding(.horizontal, .xl)
                }
            }
        }
        .viewSizeReader($store.viewSize.sending(\.sizeUpdated))
        .background(Color.backgroundSurface)
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
