import ComposableArchitecture
import Repository
import SwiftUI

// MARK: - CountryDetailView

struct CountryDetailView: View {
    var store: StoreOf<CountryDetailFeature>

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(spacing: .xs) {
                    Image(systemName: "bolt.circle")
                        .imageScale(.medium)

                    Text(store.country.voltage)
                        .font(.caption)
                }
                .foregroundStyle(.voltTint)

                HStack(spacing: .xs) {
                    Image(systemName: "waveform")
                        .imageScale(.medium)

                    Text(store.country.frequency)
                        .font(.caption)
                }
                .foregroundStyle(.frequencyTint)
            }
            .padding(.leading, .xl)

            List(store.country.sortedPlugs) { plug in
                Button {
                    store.send(.openDetail(plug: plug))
                }
                label: {
                    Card {
                        HStack {
                            SFSymbols.plugSymbol(for: plug.plugType)
                                .image
                                .imageScale(.large)
                                .bold()

                            VStack(alignment: .leading, spacing: .xs) {
                                Text(plug.name)
                                    .font(.callout)
                                    .bold()

                                Text(plug.shortInfo)
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.textRegular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .listRowSeparator(.hidden, edges: .all)
                .listSectionSeparator(.hidden, edges: .all)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(.backgroundSurface)
            .scrollContentBackground(.hidden)
            .navigationTitle(store.country.name)
        }
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
        Plug(
            id: "A",
            name: "Type A",
            shortInfo: "Used in: Australia, New Zealand, Papua New Guinea, Argentina.",
            info: "info",
            images: [URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_plug_l.png")!]
        ),
        Plug(
            id: "B",
            name: "Type B",
            shortInfo: "short info",
            info: "info",
            images: [URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_plug_l.png")!]
        )
    ]

    return NavigationStack {
        CountryDetailView(store:
            Store(
                initialState:
                CountryDetailFeature.State(country: country),
                reducer: {
                    CountryDetailFeature()
                }
            )
        )
    }
}
#endif
