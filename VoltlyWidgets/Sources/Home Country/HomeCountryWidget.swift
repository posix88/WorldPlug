import Repository
import SwiftUI
import WidgetKit

// MARK: - HomeCountryEntry

struct HomeCountryEntry: TimelineEntry {
    let date: Date
    let country: CountrySnapshot?
}

// MARK: - HomeCountryWidget

struct HomeCountryWidget: Widget {
    private let kind = "HomeCountryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeCountryTimelineProvider()) { entry in
            HomeCountryWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetStrings.string("widget.configuration.title"))
        .description(WidgetStrings.string("widget.configuration.description"))
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

struct HomeCountryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HomeCountryEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidget(entry: entry)
            case .systemMedium:
                MediumWidget(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularWidget(entry: entry)
            case .accessoryInline:
                AccessoryInlineWidget(entry: entry)
            default:
                SmallWidget(entry: entry)
            }
        }
        .widgetURL(WidgetDeepLink.country(entry.country?.code))
    }
}

// MARK: - WidgetPalette

enum WidgetPalette {
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

extension CountrySnapshot {
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

#Preview(as: .systemSmall) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: nil)
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

#Preview(as: .accessoryInline) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}
#endif
