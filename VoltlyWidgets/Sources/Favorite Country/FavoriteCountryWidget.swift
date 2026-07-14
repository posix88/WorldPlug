import Repository
import SwiftUI
import WidgetKit

// MARK: - FavoriteCountryWidget

struct FavoriteCountryWidget: Widget {
    private let kind = "FavoriteCountryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoriteCountryTimelineProvider()) { entry in
            FavoriteCountryWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetStrings.string("widget.favorite.configuration.title"))
        .description(WidgetStrings.string("widget.favorite.configuration.description"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - FavoriteCountryWidgetView

private struct FavoriteCountryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FavoriteCountryEntry

    var body: some View {
        Group {
            if entry.isPremium {
                if let country = entry.country {
                    switch family {
                    case .systemSmall:
                        FavoriteCountrySmallWidget(country: country)
                    case .systemMedium:
                        FavoriteCountryMediumWidget(country: country)
                    case .accessoryRectangular:
                        FavoriteCountryAccessoryRectangularWidget(country: country)
                    case .accessoryInline:
                        FavoriteCountryAccessoryInlineWidget(country: country)
                    default:
                        FavoriteCountrySmallWidget(country: country)
                    }
                } else {
                    FavoriteCountryEmptyWidgetView()
                }
            } else {
                FavoriteCountryLockedWidgetView()
            }
        }
        .widgetURL(entry.isPremium ? WidgetDeepLink.country(entry.country?.code) : nil)
    }
}

private struct FavoriteCountryEmptyWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            WidgetStrings.text("widget.favorite.empty.inline")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                WidgetStrings.text("widget.favorite.empty.title")
                    .font(.headline)

                WidgetStrings.text("widget.favorite.empty.description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            ZStack {
                WidgetBackground()

                VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                    WidgetStrings.text("widget.favorite.empty.title")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)

                    WidgetStrings.text("widget.favorite.empty.description")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WidgetLayout.compactPadding)
            }
            .containerBackground(for: .widget) {
                Color.clear
            }
        }
    }
}

private struct FavoriteCountryLockedWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(WidgetStrings.string("widget.favorite.locked.title"), systemImage: "lock.fill")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Label(WidgetStrings.string("widget.favorite.locked.title"), systemImage: "lock.fill")
                    .font(.headline)

                WidgetStrings.text("widget.favorite.locked.description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            ZStack {
                WidgetBackground()

                VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                    Label(WidgetStrings.string("widget.favorite.locked.title"), systemImage: "lock.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)

                    WidgetStrings.text("widget.favorite.locked.description")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WidgetLayout.compactPadding)
            }
            .containerBackground(for: .widget) {
                Color.clear
            }
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: nil, isPremium: false)
}

#Preview(as: .systemMedium) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: nil, isPremium: true)
}
#endif
