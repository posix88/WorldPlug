import Repository
import SwiftUI
import WidgetKit

// MARK: - HomeCountryEntry

struct HomeCountryEntry: TimelineEntry {
    let date: Date
    let country: CountrySnapshot?
}

// MARK: - HomeCountryTimelineProvider

struct HomeCountryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeCountryEntry {
        HomeCountryEntry(date: .now, country: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeCountryEntry) -> Void) {
        completion(HomeCountryEntry(date: .now, country: loadCountry()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeCountryEntry>) -> Void) {
        let entry = HomeCountryEntry(date: .now, country: loadCountry())
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadCountry() -> CountrySnapshot? {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let code = defaults?.string(forKey: AppGroup.homeCountryCodeKey) ?? ""
        return try? CountrySnapshotRepository.country(code: code)
    }
}

// MARK: - HomeCountryWidget

struct HomeCountryWidget: Widget {
    private let kind = "HomeCountryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeCountryTimelineProvider()) { entry in
            HomeCountryWidgetView(entry: entry)
        }
        .configurationDisplayName("Home Electrical Profile")
        .description("Keep your home plug types, voltage, and frequency on the Home Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - HomeCountryWidgetView

private struct HomeCountryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HomeCountryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            systemSmall
        case .systemMedium:
            systemMedium
        case .accessoryRectangular:
            accessoryRectangular
        case .accessoryInline:
            accessoryInline
        default:
            systemSmall
        }
    }

    private var systemSmall: some View {
        ZStack {
            widgetBackground

            VStack(alignment: .leading, spacing: 10) {
                header
                Spacer(minLength: 0)

                if let country = entry.country {
                    Text(country.flagUnicode)
                        .font(.system(size: 34))

                    Text(country.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .lineLimit(2)

                    specLine(for: country)
                    plugLine(for: country, limit: 4)
                } else {
                    emptyState
                }
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var systemMedium: some View {
        ZStack {
            widgetBackground

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    header

                    if let country = entry.country {
                        HStack(spacing: 12) {
                            Text(country.flagUnicode)
                                .font(.system(size: 38))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(country.name)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(WidgetPalette.primaryText)
                                    .lineLimit(1)

                                Text("Travel baseline")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(WidgetPalette.secondaryText)
                            }
                        }

                        specLine(for: country)
                        plugLine(for: country, limit: 6)
                    } else {
                        emptyState
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let country = entry.country {
                Text("\(country.flagUnicode) \(country.name)")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text("\(country.voltage) • \(country.frequency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(country.plugTypeIDs.map { "Type \($0)" }.joined(separator: "  "))
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            } else {
                Text("Voltly")
                    .font(.caption.weight(.semibold))
                Text("Set home country")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var accessoryInline: some View {
        Group {
            if let country = entry.country {
                Text("\(country.flagUnicode) \(country.name) \(country.voltage) \(country.frequency)")
            } else {
                Text("Voltly: Set home country")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "house.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.accent)

            Text("Home setup")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set your home country")
                .font(.headline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText)

            Text("Pick a country in Voltly to keep voltage, frequency, and plug types one glance away.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText)
                .lineLimit(4)
        }
    }

    private var widgetBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        WidgetPalette.backgroundTop,
                        WidgetPalette.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(WidgetPalette.border, lineWidth: 1)
            }
            .shadow(color: WidgetPalette.glow.opacity(0.18), radius: 18, x: 0, y: 8)
            .shadow(color: WidgetPalette.glow.opacity(0.08), radius: 6, x: 0, y: 0)
    }

    private func specLine(for country: CountrySnapshot) -> some View {
        HStack(spacing: 6) {
            infoChip(systemName: "bolt.fill", text: country.voltage, tint: WidgetPalette.accent)
            infoChip(systemName: "waveform", text: country.frequency, tint: WidgetPalette.frequency)
        }
    }

    private func plugLine(for country: CountrySnapshot, limit: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(country.plugTypeIDs.prefix(limit)), id: \.self) { plugType in
                Text("Type \(plugType)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WidgetPalette.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WidgetPalette.plugChip)
                    .clipShape(Capsule())
            }
        }
    }

    private func infoChip(systemName: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - WidgetPalette

private enum WidgetPalette {
    static let backgroundTop = Color(red: 0.08, green: 0.10, blue: 0.18)
    static let backgroundBottom = Color(red: 0.13, green: 0.16, blue: 0.28)
    static let primaryText = Color.white.opacity(0.95)
    static let secondaryText = Color.white.opacity(0.68)
    static let border = Color.white.opacity(0.10)
    static let accent = Color(red: 0.47, green: 0.84, blue: 0.98)
    static let frequency = Color(red: 0.49, green: 0.96, blue: 0.75)
    static let plugChip = Color.white.opacity(0.10)
    static let glow = Color(red: 0.47, green: 0.84, blue: 0.98)
}

private extension CountrySnapshot {
    static let preview = CountrySnapshot(
        code: "IT",
        name: "Italy",
        voltage: "230V",
        frequency: "50Hz",
        flagUnicode: "🇮🇹",
        plugTypeIDs: ["C", "F", "L"]
    )
}

#if DEBUG
#Preview(as: .systemSmall) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .systemMedium) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .accessoryRectangular) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}
#endif
