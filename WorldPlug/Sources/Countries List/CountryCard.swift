//
//  CountryCard.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 20/04/24.
//

import SwiftUI
import Repository_iOS

struct CountryCard: View {
    let country: Country

    var body: some View {
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
                            .bold()

                        Text(plug.id)
                            .font(.caption2)
                            .foregroundStyle(WorldPlugAsset.Assets.textRegular.swiftUIColor)
                            .bold()
                    }
                    .padding(.all, 5)
                    .background(WorldPlugAsset.Assets.surfaceSecondary.swiftUIColor)
                    .roundedCornerWithBorder(radius: 8, lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .embedInCard()
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
        Plug(id: "A", name: "Type A", shortInfo: "short info", info: "info", images: []),
        Plug(id: "B", name: "Type B", shortInfo: "short info", info: "info", images: []),
        Plug(id: "C", name: "Type B", shortInfo: "short info", info: "info", images: []),
        Plug(id: "D", name: "Type B", shortInfo: "short info", info: "info", images: [])
    ]

    return CountryCard(country: country)
        .padding()
}
#endif
