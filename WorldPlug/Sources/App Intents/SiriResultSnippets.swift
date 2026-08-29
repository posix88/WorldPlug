import AppIntents
import SwiftUI

// MARK: - CountryPowerSnippet

struct CountryPowerSnippet: View {
    @Environment(\.locale) private var locale
    let country: CountryEntity

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Label {
                Text(country.name)
                    .font(.headline)
            } icon: {
                Text(country.flag)
            }

            HStack(spacing: .lg) {
                snippetMetric(
                    title: localizedString(
                        LocalizationKeys.accessibilityVoltage,
                        table: .accessibility,
                        locale: locale
                    ),
                    value: country.voltage,
                    systemImage: "bolt.fill"
                )
                snippetMetric(
                    title: localizedString(
                        LocalizationKeys.accessibilityFrequency,
                        table: .accessibility,
                        locale: locale
                    ),
                    value: country.frequency,
                    systemImage: "waveform"
                )
            }

            Label(
                plugTypes,
                systemImage: "powerplug.fill"
            )
            .font(.subheadline)
        }
        .padding()
    }

    private var plugTypes: String {
        guard !country.plugTypes.isEmpty else {
            return localizedString(
                LocalizationKeys.intentCountryEntityPlugTypesUnavailable,
                locale: locale
            )
        }

        return country.plugTypes.formatted(.list(type: .and).locale(locale))
    }
}

// MARK: - DeviceCompatibilitySnippet

struct DeviceCompatibilitySnippet: View {
    @Environment(\.locale) private var locale
    let result: DeviceCompatibilityResult

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            VStack(alignment: .leading, spacing: .xs) {
                Text(result.deviceName)
                    .font(.headline)
                Text(result.destinationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            snippetStatus(
                title: result.recommendation.snippetDisplayRepresentation.title,
                systemImage: result.recommendation.snippetSystemImage,
                color: result.recommendation.snippetColor
            )

            if result.recommendation != .destinationUnavailable {
                HStack(spacing: .lg) {
                    snippetMetric(
                        title: localizedString(
                            LocalizationKeys.accessibilityVoltage,
                            table: .accessibility,
                            locale: locale
                        ),
                        value: result.destinationVoltage,
                        systemImage: "bolt.fill"
                    )
                    snippetMetric(
                        title: localizedString(
                            LocalizationKeys.accessibilityFrequency,
                            table: .accessibility,
                            locale: locale
                        ),
                        value: result.destinationFrequency,
                        systemImage: "waveform"
                    )
                }

                if !result.destinationPlugTypes.isEmpty {
                    Label(
                        result.destinationPlugTypes.formatted(.list(type: .and).locale(locale)),
                        systemImage: "powerplug.fill"
                    )
                    .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

// MARK: - NextTripRequirementsSnippet

struct NextTripRequirementsSnippet: View {
    @Environment(\.locale) private var locale
    let result: NextTripRequirementsResult

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            if !result.destinationName.isEmpty {
                VStack(alignment: .leading, spacing: .xs) {
                    Text(result.tripName?.nilIfBlank ?? result.destinationName)
                        .font(.headline)

                    if let dateRange {
                        Text(dateRange)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            snippetStatus(
                title: result.recommendation.snippetDisplayRepresentation.title,
                systemImage: result.recommendation.snippetSystemImage,
                color: result.recommendation.snippetColor
            )

            if !result.voltage.isEmpty || !result.frequency.isEmpty {
                HStack(spacing: .lg) {
                    snippetMetric(
                        title: localizedString(
                            LocalizationKeys.accessibilityVoltage,
                            table: .accessibility,
                            locale: locale
                        ),
                        value: result.voltage,
                        systemImage: "bolt.fill"
                    )
                    snippetMetric(
                        title: localizedString(
                            LocalizationKeys.accessibilityFrequency,
                            table: .accessibility,
                            locale: locale
                        ),
                        value: result.frequency,
                        systemImage: "waveform"
                    )
                }
            }

            if !result.plugTypes.isEmpty {
                Label(
                    result.plugTypes.formatted(.list(type: .and).locale(locale)),
                    systemImage: "powerplug.fill"
                )
                .font(.subheadline)
            }
        }
        .padding()
    }

    private var dateRange: String? {
        guard result.recommendation != .tripDataUnavailable else {
            return nil
        }

        guard let departureDate = result.departureDate, let returnDate = result.returnDate else {
            return nil
        }

        let calendar = Calendar.current
        guard calendar.startOfDay(for: returnDate) >= calendar.startOfDay(for: departureDate) else {
            return nil
        }

        let style = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale)
        return "\(departureDate.formatted(style)) – \(returnDate.formatted(style))"
    }
}

// MARK: - Shared components

private func snippetStatus(
    title: LocalizedStringResource,
    systemImage: String,
    color: Color
) -> some View {
    Label {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    } icon: {
        Image(systemName: systemImage)
            .foregroundStyle(color)
    }
}

private func snippetMetric(title: String, value: String, systemImage: String) -> some View {
    VStack(alignment: .leading, spacing: .xs) {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)

        Text(value)
            .font(.subheadline.weight(.semibold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private func localizedString(
    _ key: String,
    table: StringCatalog = .main,
    locale: Locale
) -> String {
    let languageCode = locale.language.languageCode?.identifier
    let localizedBundle = languageCode
        .flatMap { Bundle.main.url(forResource: $0, withExtension: "lproj") }
        .flatMap { Bundle(url: $0) }
    return String(
        localized: String.LocalizationValue(key),
        table: table.rawValue,
        bundle: localizedBundle ?? .main,
        locale: locale
    )
}

private extension DeviceCompatibilityRecommendation {
    var snippetDisplayRepresentation: DisplayRepresentation {
        Self.caseDisplayRepresentations[self] ?? DisplayRepresentation(title: "Compatibility")
    }

    var snippetSystemImage: String {
        switch self {
        case .ready: "checkmark.seal.fill"
        case .adapterNeeded: "powerplug.fill"
        case .homeCountryRequired: "house.fill"
        case .checkLabel, .frequencyRequired: "exclamationmark.triangle.fill"
        case .unsafe: "xmark.octagon.fill"
        case .destinationUnavailable: "questionmark.circle.fill"
        }
    }

    var snippetColor: Color {
        switch self {
        case .ready: .green
        case .adapterNeeded: .orange
        case .checkLabel, .destinationUnavailable, .frequencyRequired, .homeCountryRequired: .yellow
        case .unsafe: .red
        }
    }
}

private extension NextTripRequirementRecommendation {
    var snippetDisplayRepresentation: DisplayRepresentation {
        Self.caseDisplayRepresentations[self] ?? DisplayRepresentation(title: "Trip requirements")
    }

    var snippetSystemImage: String {
        switch self {
        case .plugAdapterNotExpected: "checkmark.seal.fill"
        case .adapterRecommended: "powerplug.fill"
        case .noTrip: "calendar.badge.exclamationmark"
        case .destinationUnavailable, .tripDataUnavailable: "questionmark.circle.fill"
        case .homeCountryRequired, .homeCountryUnavailable: "house.fill"
        }
    }

    var snippetColor: Color {
        switch self {
        case .plugAdapterNotExpected: .green
        case .adapterRecommended: .orange
        case .destinationUnavailable, .homeCountryRequired, .homeCountryUnavailable, .noTrip, .tripDataUnavailable: .yellow
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
