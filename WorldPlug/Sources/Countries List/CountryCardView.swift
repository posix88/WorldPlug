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
    @Environment(\.homeCountryViewModel) private var homeViewModel
    @State private var plugTapTrigger = false
    @State private var showLegend = false

    private var isHomeCountry: Bool { country.code == homeViewModel.homeCountryCode }
    private var showCompatibility: Bool { !homeViewModel.homeCountryCode.isEmpty && !isHomeCountry }

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
                            HStack {
                                Text(LocalizationKeys.compatiblePlugs.localized)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.textLight)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .accessibilityAddTraits(.isHeader)

                                if showCompatibility {
                                    Spacer()
                                    Button {
                                        showLegend.toggle()
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.footnote)
                                            .foregroundStyle(.textLighter)
                                    }
                                    .buttonStyle(.plain)
                                    .popover(isPresented: $showLegend, arrowEdge: .top) {
                                        CompatibilityLegendView()
                                            .presentationCompactAdaptation(.popover)
                                    }
                                    .accessibilityLabel(LocalizationKeys.accessibilityCompatibilityLegend.localized(
                                        from: .accessibility
                                    ))
                                }
                            }

                            // Simple plug type titles
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: .md) {
                                ForEach(country.sortedPlugs) { plug in
                                    NavigationLink(value: plug) {
                                        HStack(spacing: .md) {
                                            SFSymbols.plugSymbol(for: plug.plugType)
                                                .image
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.textRegular)
                                                .overlay(alignment: .topTrailing) {
                                                    if showCompatibility {
                                                        CompatibilityBadge(
                                                            compatibility: homeViewModel.plugCompatibility(
                                                                for: plug,
                                                                in: country
                                                            )
                                                        )
                                                        .offset(x: 6, y: -6)
                                                    }
                                                }

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
                                    .accessibilityLabel(LocalizationKeys.accessibilityPlugTypeLabel.localized(
                                        from: .accessibility,
                                        plug.id
                                    ))
                                    .accessibilityHint(LocalizationKeys.accessibilityPlugTypeHint.localized(
                                        from: .accessibility,
                                        plug.id
                                    ))
                                    .accessibilityAddTraits(.isButton)
                                    .simultaneousGesture(TapGesture().onEnded { plugTapTrigger.toggle() })
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(LocalizationKeys.accessibilityCompatiblePlugTypes.localized(from: .accessibility))
                            .sensoryFeedback(.selection, trigger: plugTapTrigger)
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
                            HStack(spacing: .sm) {
                                Text(country.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.textRegular)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                if isHomeCountry {
                                    Text(LocalizationKeys.homeCountryBadge.localized)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, .sm)
                                        .padding(.vertical, 3)
                                        .background(.voltTint)
                                        .roundedCorner(radius: 6)
                                        .accessibilityLabel(LocalizationKeys.accessibilityHomeCountryBadge
                                            .localized(from: .accessibility)
                                        )
                                }
                            }

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
        .contextMenu {
            if isHomeCountry {
                Button(role: .destructive) {
                    homeViewModel.clearHome()
                } label: {
                    Label(LocalizationKeys.homeCountryRemove.localized, systemImage: "house.fill")
                }
            } else {
                Button {
                    homeViewModel.setHome(code: country.code)
                } label: {
                    Label(LocalizationKeys.homeCountrySet.localized, systemImage: "house.fill")
                }
            }
        }
    }
}

// MARK: - CompatibilityBadge

private struct CompatibilityBadge: View {
    let compatibility: PlugCompatibility

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 13, height: 13)
            .background(badgeColor, in: Circle())
            .accessibilityLabel(compatibility.accessibilityLabel)
    }

    private var iconName: String {
        switch compatibility {
        case .compatible: "checkmark"
        case .adapterNeeded: "powerplug.fill"
        case .converterRequired: "exclamationmark"
        }
    }

    private var badgeColor: Color {
        switch compatibility {
        case .compatible: .green
        case .adapterNeeded: .orange
        case .converterRequired: .red
        }
    }
}

// MARK: - CompatibilityLegendView

private struct CompatibilityLegendView: View {
    private struct LegendRow: View {
        let compatibility: PlugCompatibility
        var body: some View {
            HStack(alignment: .top, spacing: .lg) {
                CompatibilityBadge(compatibility: compatibility)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: .xxs) {
                    Text(compatibility.legendTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textRegular)
                    Text(compatibility.legendDescription)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .xl) {
            Text(LocalizationKeys.compatibilityLegendTitle.localized)
                .font(.headline)
                .foregroundStyle(.textRegular)

            VStack(alignment: .leading, spacing: .lg) {
                LegendRow(compatibility: .compatible)
                LegendRow(compatibility: .adapterNeeded)
                LegendRow(compatibility: .converterRequired)
            }
        }
        .padding(.xxl)
        .frame(minWidth: 260)
    }
}

// MARK: - PlugCompatibility + Legend strings

private extension PlugCompatibility {
    var legendTitle: String {
        switch self {
        case .compatible: LocalizationKeys.compatibilityLegendCompatibleTitle.localized
        case .adapterNeeded: LocalizationKeys.compatibilityLegendAdapterTitle.localized
        case .converterRequired: LocalizationKeys.compatibilityLegendConverterTitle.localized
        }
    }

    var legendDescription: String {
        switch self {
        case .compatible: LocalizationKeys.compatibilityLegendCompatibleDesc.localized
        case .adapterNeeded: LocalizationKeys.compatibilityLegendAdapterDesc.localized
        case .converterRequired: LocalizationKeys.compatibilityLegendConverterDesc.localized
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .compatible: LocalizationKeys.accessibilityPlugCompatible.localized(from: .accessibility)
        case .adapterNeeded: LocalizationKeys.accessibilityPlugAdapterNeeded.localized(from: .accessibility)
        case .converterRequired: LocalizationKeys.accessibilityPlugConverterRequired.localized(from: .accessibility)
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
                        .padding(.horizontal, .md)
                        .padding(.vertical, .sm)
                        .background(.surfaceSecondary)
                        .roundedCorner(radius: 8)
                }
                .contentShape(Rectangle())
            }
            .accessibilityAddTraits(.isButton)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isExpanded)
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
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "B",
            name: "Type B",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "C",
            name: "Type C",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "D",
            name: "Type D",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "E",
            name: "Type E",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "F",
            name: "Type F",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "G",
            name: "Type G",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "H",
            name: "Type H",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "I",
            name: "Type I",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "J",
            name: "Type J",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "K",
            name: "Type K",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "L",
            name: "Type L",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "M",
            name: "Type M",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "N",
            name: "Type N",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        ),
        Plug(
            id: "O",
            name: "Type O",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
        )
    ]

    let homeVM = PreviewHomeCountryViewModel(homeCountryCode: "GB", plugTypeIDs: ["C", "G"])
    return CountryCard(country: country)
        .environment(\.homeCountryViewModel, homeVM)
}
#endif
