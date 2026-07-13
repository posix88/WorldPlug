import Repository
import SwiftUI

// MARK: - CountryBrowserRow

struct CountryBrowserRow: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?

    @Environment(\.homeCountryViewModel) private var homeViewModel

    private var isHomeCountry: Bool {
        country.code == homeViewModel.homeCountryCode
    }

    var body: some View {
        NavigationLink(value: country) {
            Card(insets: .init(top: .md, leading: .lg, bottom: .md, trailing: .lg), shadow: .subtle) {
                summary
            }
        }
        .buttonStyle(.plain)
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
                    CompatibilityStatusIndicator(summary: compatibility)
                }

                SFSymbols.chevronRight.image
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textLighter)
            }
            .frame(width: 116, alignment: .trailing)
            .layoutPriority(2)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
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
}

// MARK: - CompatibilityStatusIndicator

private struct CompatibilityStatusIndicator: View {
    let summary: CountryCompatibilitySummary

    var body: some View {
        ZStack {
            Circle()
                .fill(summary.color.opacity(0.14))
                .frame(width: 30, height: 30)

            summary.icon.image
                .imageScale(.small)
        }
        .foregroundStyle(summary.color)
        .accessibilityElement()
        .accessibilityLabel(summary.title)
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

    return NavigationStack {
        CountryBrowserRow(country: country, compatibility: .compatible)
            .padding(.xxl)
            .modelContainer(container)
            .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "GB", plugTypeIDs: ["G"]))
    }
}
#endif
