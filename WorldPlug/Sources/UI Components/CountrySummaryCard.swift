import Repository
import SwiftUI

// MARK: - CountrySummaryCard

/// The shared visual representation of a country in browsable country lists.
struct CountrySummaryCard: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?
    let isHomeCountry: Bool

    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var minimumRowHeight: CGFloat = 56

    var body: some View {
        Card(insets: .init(top: .md, leading: .lg, bottom: .md, trailing: .lg), shadow: .subtle) {
            // `Group` around the branch, not around a single child: its content is
            // `_ConditionalContent`, so the shared modifiers below apply to both layouts
            // without being repeated.
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    CountrySummaryStackedContent(
                        name: country.localizedName(in: locale),
                        voltage: country.voltage,
                        frequency: country.frequency,
                        isHomeCountry: isHomeCountry,
                        compatibility: compatibility
                    )
                } else {
                    CountrySummaryRowContent(
                        flag: country.flagUnicode,
                        name: country.localizedName(in: locale),
                        voltage: country.voltage,
                        frequency: country.frequency,
                        isHomeCountry: isHomeCountry,
                        compatibility: compatibility
                    )
                }
            }
            .frame(minHeight: minimumRowHeight)
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var components = [
            country.localizedName(in: locale),
            "\(String(localized: LocalizationKeys.accessibilityVoltage)): \(country.voltage)",
            "\(String(localized: LocalizationKeys.accessibilityFrequency)): \(country.frequency)"
        ]

        if isHomeCountry {
            components.append(String(localized: LocalizationKeys.homeCountryBadge))
        }

        if let compatibility {
            components.append(String(localized: compatibility.title))
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - CountrySummaryRowContent

/// The normal-text-size layout: flag, name over pills, trailing status column, all on one row.
private struct CountrySummaryRowContent: View {
    let flag: String
    let name: String
    let voltage: String
    let frequency: String
    let isHomeCountry: Bool
    let compatibility: CountryCompatibilitySummary?

    var body: some View {
        HStack(spacing: .md) {
            CountryFlagTile(flag: flag)

            VStack(alignment: .leading, spacing: .md) {
                CountryCardName(name: name, isHomeCountry: isHomeCountry)
                CountrySpecificationPills(voltage: voltage, frequency: frequency)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            CountryCardTrailing(compatibility: compatibility)
        }
    }
}

// MARK: - CountrySummaryStackedContent

/// The accessibility-text-size layout. Subtractive rather than taller: the flag tile and the
/// chevron are dropped — the name already names the country and the whole card is already a
/// button — and their width goes to the two things that matter, the country name and the
/// voltage/frequency pair. Kept side by side, those decorations left the middle column so narrow
/// that the voltage truncated to an ellipsis and country names broke every three or four letters.
private struct CountrySummaryStackedContent: View {
    let name: String
    let voltage: String
    let frequency: String
    let isHomeCountry: Bool
    let compatibility: CountryCompatibilitySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            HStack(alignment: .firstTextBaseline, spacing: .md) {
                CountryCardName(name: name, isHomeCountry: isHomeCountry)

                Spacer(minLength: .sm)

                if let compatibility {
                    CompatibilityStatusIndicator(summary: compatibility)
                }
            }

            CountrySpecificationPills(voltage: voltage, frequency: frequency)
        }
    }
}

// MARK: - CountryFlagTile

private struct CountryFlagTile: View {
    let flag: String

    @ScaledMetric(relativeTo: .headline) private var glyphSize: CGFloat = 30
    @ScaledMetric(relativeTo: .headline) private var tileSize: CGFloat = 40

    var body: some View {
        Text(flag)
            .font(.system(size: glyphSize))
            .frame(width: tileSize, height: tileSize)
            .background(.flagBackground)
            .roundedCorner(radius: 10)
    }
}

// MARK: - CountryCardName

private struct CountryCardName: View {
    let name: String
    let isHomeCountry: Bool

    var body: some View {
        HStack(spacing: .sm) {
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.textRegular)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if isHomeCountry {
                HomeCountryIndicator()
            }
        }
    }
}

// MARK: - CountrySpecificationPills

/// `ViewThatFits` rather than a `dynamicTypeSize` branch: whether both pills share a line depends
/// on the values too ("220V / 230V" is far wider than "100V"), not just the text size.
private struct CountrySpecificationPills: View {
    let voltage: String
    let frequency: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: .xs) {
                VoltagePill(voltage: voltage)
                FrequencyPill(frequency: frequency)
            }

            VStack(alignment: .leading, spacing: .xs) {
                VoltagePill(voltage: voltage)
                FrequencyPill(frequency: frequency)
            }
        }
    }
}

// MARK: - VoltagePill

private struct VoltagePill: View {
    let voltage: String

    var body: some View {
        ElectricalSpecificationPill(
            icon: .boltCircleFill,
            label: LocalizationKeys.accessibilityVoltage,
            value: voltage,
            color: .voltTint
        )
    }
}

// MARK: - FrequencyPill

private struct FrequencyPill: View {
    let frequency: String

    var body: some View {
        ElectricalSpecificationPill(
            icon: .waveform,
            label: LocalizationKeys.accessibilityFrequency,
            value: frequency,
            color: .frequencyTint
        )
    }
}

// MARK: - CountryCardTrailing

private struct CountryCardTrailing: View {
    let compatibility: CountryCompatibilitySummary?

    var body: some View {
        VStack(alignment: .trailing, spacing: .sm) {
            if let compatibility {
                CompatibilityStatusIndicator(summary: compatibility)
            }

            SFSymbols.chevronRight.image
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.textLighter)
        }
        .layoutPriority(2)
    }
}

// MARK: - CompatibilityStatusIndicator

private struct CompatibilityStatusIndicator: View {
    let summary: CountryCompatibilitySummary

    @ScaledMetric(relativeTo: .headline) private var diameter: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(summary.color.opacity(0.14))
                .frame(width: diameter, height: diameter)

            summary.icon.image
                .imageScale(.small)
        }
        .foregroundStyle(summary.color)
        .accessibilityElement()
        .accessibilityLabel(summary.title)
    }
}

#if DEBUG
#Preview {
    CountrySummaryCard(
        country: Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵"),
        compatibility: .adapterNeeded,
        isHomeCountry: false
    )
    .padding()
    .background { AppMeshBackground() }
}
#endif
