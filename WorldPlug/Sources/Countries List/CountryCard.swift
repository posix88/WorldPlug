//
//  CountryCard.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 20/04/24.
//

import Repository
import SwiftUI

// MARK: - CountryCard

struct CountryCard: View {
    let country: Country
    @Binding var selectedPlug: Plug?

    var body: some View {
        Card(shadow: .subtle) {
            DisclosureGroup(
                content: {
                    VStack(alignment: .leading, spacing: .xxl) {
                        HStack(spacing: .xl) {
                            HStack(spacing: .sm) {
                                SFSymbols.boltCircleFill
                                    .image
                                    .imageScale(.medium)

                                Text(country.voltage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.voltTint)
                            .padding(.horizontal, .lg)
                            .padding(.vertical, .md)
                            .background(.voltTint.opacity(0.1))
                            .roundedCorner(radius: 8)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(LocalizationKeys.accessibilityVoltage.localized(from: .accessibility))
                            .accessibilityValue(country.voltage)

                            HStack(spacing: .sm) {
                                SFSymbols.waveform
                                    .image
                                    .imageScale(.medium)

                                Text(country.frequency)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.frequencyTint)
                            .padding(.horizontal, .lg)
                            .padding(.vertical, .md)
                            .background(.frequencyTint.opacity(0.1))
                            .roundedCorner(radius: 8)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(LocalizationKeys.accessibilityFrequency.localized(from: .accessibility))
                            .accessibilityValue(country.frequency)

                            Spacer()

                            // Plug count indicator
                            HStack(spacing: .xs) {
                                SFSymbols.powerPlug
                                    .image
                                    .imageScale(.small)

                                Text("\(country.plugs.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.textLight)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(LocalizationKeys.accessibilityPlugTypesCount.localized(from: .accessibility))
                            .accessibilityValue("\(country.plugs.count)")
                        }

                        // Enhanced plugs section
                        VStack(alignment: .leading, spacing: .lg) {
                            Text(LocalizationKeys.compatiblePlugs.localized)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textLight)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .accessibilityAddTraits(.isHeader)

                            // Simple plug type titles
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: .md) {
                                ForEach(country.sortedPlugs) { plug in
                                    Button {
                                        selectedPlug = plug
                                    } label: {
                                        HStack(spacing: .md) {
                                            SFSymbols.plugSymbol(for: plug.plugType)
                                                .image
                                                .font(.callout)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.textRegular)

                                            Text(LocalizationKeys.plugTypePrefix.localized(plug.id))
                                                .font(.callout)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.textRegular)

                                            Spacer()

                                            SFSymbols.chevronRight
                                                .image
                                                .imageScale(.small)
                                                .foregroundStyle(.textLighter)
                                        }
                                        .padding(.horizontal, .lg)
                                        .padding(.vertical, .md)
                                        .background(.surfaceSecondary)
                                        .roundedCorner(radius: 8)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .accessibilityLabel(LocalizationKeys.accessibilityPlugTypeLabel.localized(
                                        from: .accessibility,
                                        plug.id
                                    ))
                                    .accessibilityHint(LocalizationKeys.accessibilityPlugTypeHint.localized(
                                        from: .accessibility,
                                        plug.id
                                    ))
                                    .accessibilityAddTraits(.isButton)
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(LocalizationKeys.accessibilityCompatiblePlugTypes.localized(from: .accessibility))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(LocalizationKeys.accessibilityCountryDetails.localized(
                        from: .accessibility,
                        country.name
                    ))
                },
                label: {
                    HStack(spacing: .xl) {
                        // Enhanced flag display with prominent background
                        Text(country.flagUnicode)
                            .font(.system(size: 36))
                            .frame(width: 44, height: 44)
                            .background(.flagBackground)
                            .roundedCorner(radius: 10)

                        VStack(alignment: .leading, spacing: .xs) {
                            Text(country.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textRegular)
                                .lineLimit(2) // Prevent very long country names from breaking layout
                                .multilineTextAlignment(.leading)

                            Text(LocalizationKeys.plugType.localized(country.plugs.count))
                                .font(.subheadline)
                                .foregroundStyle(.textLight)
                        }

                        Spacer(minLength: .md) // Ensure minimum space before chevron
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(LocalizationKeys.accessibilityCountryCardHint.localized(
                        from: .accessibility,
                        country.name
                    ))
                }
            )
            .disclosureGroupStyle(EnhancedDisclosureStyle())
            .tint(.textRegular)
        }
    }
}

// MARK: - EnhancedDisclosureStyle

/// Enhanced disclosure style with smooth animations
struct EnhancedDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label

                    SFSymbols.chevronDown
                        .image
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.textLight)
                        .rotationEffect(
                            configuration.isExpanded ? .degrees(180) : .degrees(0),
                            anchor: .center
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: configuration.isExpanded)
                        .padding(.horizontal, .md)
                        .padding(.vertical, .sm)
                        .background(.surfaceSecondary)
                        .roundedCorner(radius: 8)
                }
                .contentShape(Rectangle())
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(configuration.isExpanded ? LocalizationKeys.accessibilityCollapseCountryDetails
                .localized(from: .accessibility) : LocalizationKeys.accessibilityExpandCountryDetails
                .localized(from: .accessibility)
            )
            .accessibilityHint(configuration.isExpanded ? LocalizationKeys.accessibilityHideDetailsHint
                .localized(from: .accessibility) : LocalizationKeys.accessibilityShowDetailsHint.localized(from: .accessibility)
            )
            // Add solid background to header to prevent content bleeding through
            .background(.cardSurface)
            .zIndex(1) // Ensure header stays on top

            if configuration.isExpanded {
                configuration.content
                    .padding(.top, .xxl)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: configuration.isExpanded)
            }
        }
        .clipped() // Clip overflow to prevent ugly transitions
    }
}

// MARK: - ScaleButtonStyle

/// Scale button style for better interaction feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
