import Repository
import SwiftUI

// MARK: - CountryBrowserRow

struct CountryBrowserRow: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?

    @Environment(\.homeCountryViewModel) private var homeViewModel
    @State private var isExpanded = false
    @State private var plugTapTrigger = false

    private var isHomeCountry: Bool {
        country.code == homeViewModel.homeCountryCode
    }

    var body: some View {
        Card(insets: .init(top: .md, leading: .lg, bottom: .md, trailing: .lg), shadow: .subtle) {
            VStack(alignment: .leading, spacing: .lg) {
                Button {
                    withAnimation(.snappy) {
                        isExpanded.toggle()
                    }
                } label: {
                    summary
                }
                .buttonStyle(.plain)
                .frame(minHeight: 56)
                .accessibilityHint(isExpanded ? LocalizationKeys.accessibilityHideDetailsHint
                    .localized(from: .accessibility) : LocalizationKeys.accessibilityShowDetailsHint
                    .localized(from: .accessibility)
                )

                if isExpanded {
                    details
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
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

    private var summary: some View {
        HStack(spacing: .md) {
            Text(country.flagUnicode)
                .font(.system(size: 30))
                .frame(width: 40, height: 40)
                .background(.flagBackground)
                .roundedCorner(radius: 10)

            VStack(alignment: .leading, spacing: .xs) {
                HStack(spacing: .sm) {
                    Text(country.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textRegular)
                        .lineLimit(1)
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
                    }
                }

                HStack(spacing: .xs) {
                    specTag(
                        icon: .boltCircleFill,
                        label: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                        value: country.voltage,
                        color: .voltTint
                    )
                    specTag(
                        icon: .waveform,
                        label: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                        value: country.frequency,
                        color: .frequencyTint
                    )
                }

                plugTypeTags
            }
            .layoutPriority(1)

            Spacer(minLength: .sm)

            VStack(alignment: .trailing, spacing: .sm) {
                if let compatibility {
                    CompatibilityStatusPill(summary: compatibility)
                }

                SFSymbols.chevronDown.image
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textLighter)
                    .rotationEffect(isExpanded ? .degrees(180) : .zero)
            }
            .frame(width: 116, alignment: .trailing)
            .layoutPriority(2)
        }
        .contentShape(Rectangle())
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: .lg) {
            Divider()

            Text(LocalizationKeys.compatiblePlugs.localized)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.textLight)
                .textCase(.uppercase)
                .tracking(0.5)

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

                            Text(LocalizationKeys.plugTypePrefix.localized(plug.id))
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.textRegular)

                            Spacer()

                            if let plugCompatibility = plugCompatibility(for: plug) {
                                SmallCompatibilityBadge(compatibility: plugCompatibility)
                            }

                            SFSymbols.chevronRight.image
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
            .sensoryFeedback(.selection, trigger: plugTapTrigger)
        }
    }

    private var plugTypeTags: some View {
        HStack(spacing: .xs) {
            ForEach(country.sortedPlugs.prefix(5)) { plug in
                Text(plug.id)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.textRegular)
                    .frame(minWidth: 18)
                    .padding(.horizontal, .xs)
                    .padding(.vertical, 2)
                    .background(.surfaceSecondary)
                    .roundedCorner(radius: 5)
            }

            if country.sortedPlugs.count > 5 {
                Text("+\(country.sortedPlugs.count - 5)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.textLight)
            }
        }
    }

    private func specTag(icon: SFSymbols, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            icon.image
                .imageScale(.small)

            Text(value)
                .lineLimit(1)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(color)
        .padding(.horizontal, .xs)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .roundedCorner(radius: 5)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private func plugCompatibility(for plug: Plug) -> PlugCompatibility? {
        guard !homeViewModel.homeCountryCode.isEmpty, !isHomeCountry else {
            return nil
        }

        return homeViewModel.plugCompatibility(for: plug, in: country)
    }
}

// MARK: - CompatibilityStatusPill

private struct CompatibilityStatusPill: View {
    let summary: CountryCompatibilitySummary

    var body: some View {
        HStack(spacing: .xs) {
            summary.icon.image
                .imageScale(.small)

            Text(summary.title)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundStyle(summary.color)
        .padding(.horizontal, .sm)
        .padding(.vertical, .xs)
        .background(summary.color.opacity(0.12))
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - SmallCompatibilityBadge

private struct SmallCompatibilityBadge: View {
    let compatibility: PlugCompatibility

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 13, height: 13)
            .background(color, in: Circle())
            .accessibilityLabel(accessibilityLabel)
    }

    private var iconName: String {
        switch compatibility {
        case .compatible: "checkmark"
        case .adapterNeeded: "powerplug.fill"
        case .converterRequired: "exclamationmark"
        }
    }

    private var color: Color {
        switch compatibility {
        case .compatible: .green
        case .adapterNeeded: .orange
        case .converterRequired: .red
        }
    }

    private var accessibilityLabel: String {
        switch compatibility {
        case .compatible: LocalizationKeys.accessibilityPlugCompatible.localized(from: .accessibility)
        case .adapterNeeded: LocalizationKeys.accessibilityPlugAdapterNeeded.localized(from: .accessibility)
        case .converterRequired: LocalizationKeys.accessibilityPlugConverterRequired.localized(from: .accessibility)
        }
    }
}

#if DEBUG
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)
    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    container.mainContext.insert(country)
    country.plugs = [
        Plug(
            id: "C",
            name: "Type C",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "CEE 7/16")
        ),
        Plug(
            id: "F",
            name: "Type F",
            shortInfo: "short info",
            info: "info",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "CEE 7/4")
        )
    ]

    return CountryBrowserRow(country: country, compatibility: .compatible)
        .padding(.xxl)
        .modelContainer(container)
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "GB", plugTypeIDs: ["G"]))
}
#endif
