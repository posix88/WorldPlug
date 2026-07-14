import Repository
import SwiftUI
import WidgetKit

struct NextTripAccessoryRectangularWidget: View {
    let country: CountrySnapshot
    let departureDate: Date

    private var countdown: NextTripCountdown { NextTripCountdown(departureDate: departureDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(country.widgetTitle, systemImage: "airplane.departure")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(countdown.displayText)
                .font(.caption.weight(.bold))
            Text(departureDate, format: .dateTime.day().month(.abbreviated))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

#if DEBUG
#Preview(as: .accessoryRectangular) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), isPremium: true)
}
#endif
