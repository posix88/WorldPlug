import Repository
import SwiftUI

// MARK: - CountryBrowserRow

struct CountryBrowserRow: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?

    @Environment(\.homeCountryViewModel) private var homeViewModel
    @Environment(\.locale) private var locale

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

            VStack(alignment: .leading, spacing: .md) {
                HStack(spacing: .sm) {
                    Text(country.localizedName(in: locale))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textRegular)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    if isHomeCountry {
                        HomeCountryIndicator()
                    }
                }

                HStack(spacing: .xs) {
                    ElectricalSpecificationPill(
                        icon: .boltCircleFill,
                        label: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                        value: country.voltage,
                        color: .voltTint
                    )
                    ElectricalSpecificationPill(
                        icon: .waveform,
                        label: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                        value: country.frequency,
                        color: .frequencyTint
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "CEE 7/16")
        ),
        Plug(
            id: "F",
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
