//
//  CountryCard.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 20/04/24.
//

import SwiftUI
import Repository

struct CountryCard: View {
    let country: Country
    @Binding var selectedPlug: Plug?
    
    var body: some View {
        Card {
            DisclosureGroup(
                content: {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.circle")
                                    .imageScale(.medium)
                                
                                Text(country.voltage)
                                    .font(.caption)
                            }
                            .foregroundStyle(.voltTint)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .imageScale(.medium)
                                
                                Text(country.frequency)
                                    .font(.caption)
                            }
                            .foregroundStyle(.frequencyTint)
                        }
                        
                        VStack(alignment: .leading) {
                            ForEach(country.sortedPlugs) { plug in
                                Button {
                                    selectedPlug = plug
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: plug.plugSymbol)
                                            .imageScale(.medium)
                                            .bold()
                                            .frame(width: 30, height: 30)
                                        
                                        Text(plug.name)
                                            .font(.callout)
                                            .foregroundStyle(Color.textRegular)
                                        
                                        Image(systemName: "chevron.right")
                                            .imageScale(.small)
                                    }
                                    .padding(.all, 5)
                                    .background(Color.surfaceSecondary)
                                    .roundedCornerWithBorder(radius: 8, lineWidth: 1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                },
                label: {
                    HStack {
                        Text(country.flagUnicode)
                            .font(.system(size: 30))
                        
                        Text(country.name)
                            .font(.headline)
                            .foregroundStyle(Color.textRegular)
                    }
                }
            )
            .disclosureGroupStyle(MyDisclosureStyle())
            .tint(Color.textRegular)
        }
    }
}

struct MyDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                    Spacer()
                    Image(systemName: "chevron.right")
                        .animation(.spring, value: configuration.isExpanded)
                        .rotationEffect(configuration.isExpanded ? .degrees(90) : .zero, anchor: .center)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NoButtonStyle())
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
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
        Plug(id: "C", name: "Type C", shortInfo: "short info", info: "info", images: []),
        Plug(id: "D", name: "Type D", shortInfo: "short info", info: "info", images: []),
        Plug(id: "E", name: "Type E", shortInfo: "short info", info: "info", images: []),
        Plug(id: "F", name: "Type F", shortInfo: "short info", info: "info", images: []),
        Plug(id: "G", name: "Type G", shortInfo: "short info", info: "info", images: []),
        Plug(id: "H", name: "Type H", shortInfo: "short info", info: "info", images: []),
        Plug(id: "I", name: "Type I", shortInfo: "short info", info: "info", images: []),
        Plug(id: "J", name: "Type J", shortInfo: "short info", info: "info", images: []),
        Plug(id: "K", name: "Type K", shortInfo: "short info", info: "info", images: []),
        Plug(id: "L", name: "Type L", shortInfo: "short info", info: "info", images: []),
        Plug(id: "M", name: "Type M", shortInfo: "short info", info: "info", images: []),
        Plug(id: "N", name: "Type N", shortInfo: "short info", info: "info", images: []),
        Plug(id: "O", name: "Type O", shortInfo: "short info", info: "info", images: [])
    ]

    return CountryCard(country: country, selectedPlug: .constant(nil))
        .padding()
}
#endif
