import Repository
import SwiftUI
import WidgetKit

struct NextTripWidget: Widget {
    private let kind = "NextTripWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTripTimelineProvider()) { entry in
            NextTripWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetStrings.string("widget.next.trip.configuration.title"))
        .description(WidgetStrings.string("widget.next.trip.configuration.description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

private struct NextTripWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextTripEntry

    var body: some View {
        Group {
            if !entry.isPremium {
                NextTripLockedWidgetView()
            } else if let country = entry.country, let departureDate = entry.departureDate {
                switch family {
                case .systemSmall:
                    NextTripSmallWidget(country: country, departureDate: departureDate)
                case .systemMedium:
                    NextTripMediumWidget(
                        homeCountry: entry.homeCountry,
                        country: country,
                        departureDate: departureDate
                    )
                case .systemLarge:
                    NextTripLargeWidget(
                        homeCountry: entry.homeCountry,
                        country: country,
                        departureDate: departureDate
                    )
                case .accessoryRectangular:
                    NextTripAccessoryRectangularWidget(country: country, departureDate: departureDate)
                case .accessoryInline:
                    NextTripAccessoryInlineWidget(country: country, departureDate: departureDate)
                default:
                    NextTripSmallWidget(country: country, departureDate: departureDate)
                }
            } else {
                NextTripEmptyWidgetView()
            }
        }
        .widgetURL(entry.isPremium ? WidgetDeepLink.country(entry.country?.code) : nil)
    }
}

struct NextTripCountdown {
    let departureDate: Date

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: departureDate)
        ).day ?? 0)
    }

    var displayText: String {
        daysRemaining == 0
            ? WidgetStrings.string("widget.next.trip.today")
            : WidgetStrings.string("widget.next.trip.days.remaining", daysRemaining)
    }

    var shortDisplayText: String {
        daysRemaining == 0
            ? WidgetStrings.string("widget.next.trip.today")
            : WidgetStrings.string("widget.next.trip.days.short", daysRemaining)
    }
}

private struct NextTripEmptyWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            WidgetStrings.text("widget.next.trip.empty.inline")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                WidgetStrings.text("widget.next.trip.empty.title")
                    .font(.headline)
                WidgetStrings.text("widget.next.trip.empty.description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            ZStack {
                WidgetBackground()
                VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                    WidgetStrings.text("widget.next.trip.empty.title")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                    WidgetStrings.text("widget.next.trip.empty.description")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WidgetLayout.compactPadding)
            }
            .containerBackground(for: .widget) { Color.clear }
        }
    }
}

private struct NextTripLockedWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(WidgetStrings.string("widget.next.trip.locked.title"), systemImage: "lock.fill")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Label(WidgetStrings.string("widget.next.trip.locked.title"), systemImage: "lock.fill")
                    .font(.headline)
                WidgetStrings.text("widget.next.trip.locked.description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            ZStack {
                WidgetBackground()
                VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                    Label(WidgetStrings.string("widget.next.trip.locked.title"), systemImage: "lock.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                    WidgetStrings.text("widget.next.trip.locked.description")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WidgetLayout.compactPadding)
            }
            .containerBackground(for: .widget) { Color.clear }
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: nil, country: nil, departureDate: nil, isPremium: false)
}

#Preview(as: .systemMedium) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: nil, country: nil, departureDate: nil, isPremium: true)
}
#endif
