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
            } else if let country = entry.country,
                      let departureDate = entry.departureDate,
                      !NextTripCountdown(departureDate: departureDate, returnDate: entry.returnDate).isExpired {
                switch family {
                case .systemSmall:
                    NextTripSmallWidget(country: country, departureDate: departureDate, returnDate: entry.returnDate)
                case .systemMedium:
                    NextTripMediumWidget(
                        homeCountry: entry.homeCountry,
                        country: country,
                        departureDate: departureDate,
                        returnDate: entry.returnDate
                    )
                case .systemLarge:
                    NextTripLargeWidget(
                        homeCountry: entry.homeCountry,
                        country: country,
                        departureDate: departureDate,
                        returnDate: entry.returnDate
                    )
                case .accessoryRectangular:
                    NextTripAccessoryRectangularWidget(country: country, departureDate: departureDate, returnDate: entry.returnDate)
                case .accessoryInline:
                    NextTripAccessoryInlineWidget(country: country, departureDate: departureDate, returnDate: entry.returnDate)
                default:
                    NextTripSmallWidget(country: country, departureDate: departureDate, returnDate: entry.returnDate)
                }
            } else {
                NextTripEmptyWidgetView()
            }
        }
        .widgetURL(isNavigableTrip ? WidgetDeepLink.country(entry.country?.code) : nil)
    }

    private var isNavigableTrip: Bool {
        guard entry.isPremium, let departureDate = entry.departureDate else {
            return false
        }

        return !NextTripCountdown(departureDate: departureDate, returnDate: entry.returnDate).isExpired
    }
}

struct NextTripCountdown {
    let departureDate: Date
    let returnDate: Date

    var isOnVacation: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return today >= Calendar.current.startOfDay(for: departureDate)
            && today <= Calendar.current.startOfDay(for: returnDate)
    }

    var isExpired: Bool {
        return Calendar.current.startOfDay(for: .now) > Calendar.current.startOfDay(for: returnDate)
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: departureDate)
        ).day ?? 0)
    }

    var displayText: String {
        isOnVacation
            ? WidgetStrings.string("widget.next.trip.enjoy")
            : daysRemaining == 0
            ? WidgetStrings.string("widget.next.trip.today")
            : WidgetStrings.string("widget.next.trip.days.remaining", daysRemaining)
    }

    var shortDisplayText: String {
        isOnVacation
            ? WidgetStrings.string("widget.next.trip.enjoy")
            : daysRemaining == 0
            ? WidgetStrings.string("widget.next.trip.today")
            : WidgetStrings.string("widget.next.trip.days.short", daysRemaining)
    }

    var symbolName: String {
        isOnVacation ? "sun.max.fill" : "airplane.departure"
    }

    var titleKey: String {
        isOnVacation ? "widget.next.trip.vacation.label" : "widget.next.trip.label"
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
    NextTripEntry(date: .now, homeCountry: nil, country: nil, departureDate: nil, returnDate: .distantPast, isPremium: false)
}

#Preview(as: .systemMedium) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: nil, country: nil, departureDate: nil, returnDate: .distantPast, isPremium: true)
}
#endif
