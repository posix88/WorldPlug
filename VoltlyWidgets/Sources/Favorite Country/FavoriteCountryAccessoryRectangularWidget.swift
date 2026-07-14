import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountryAccessoryRectangularWidget: View {
    let country: CountrySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(country.widgetTitle, systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Text("\(country.voltage) • \(country.frequency)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(country.plugTypeIDs.map { WidgetStrings.string("widget.plug.type", $0) }.joined(separator: "  "))
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

#if DEBUG
#Preview(as: .accessoryRectangular) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
}
#endif
