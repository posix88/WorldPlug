import Repository
import SwiftUI

/// The shared visual representation of a country in browsable country lists.
struct CountrySummaryCard: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?
    let isHomeCountry: Bool

    @Environment(\.locale) private var locale

    var body: some View {
        Card(insets: .init(top: .md, leading: .lg, bottom: .md, trailing: .lg), shadow: .subtle) {
            HStack(spacing: .md) {
                flag
                countryInformation
                trailingInformation
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
    }

    private var flag: some View {
        Text(country.flagUnicode)
            .font(.system(size: 30))
            .frame(width: 40, height: 40)
            .background(.flagBackground)
            .roundedCorner(radius: 10)
    }

    private var countryInformation: some View {
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
    }

    private var trailingInformation: some View {
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
}

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
