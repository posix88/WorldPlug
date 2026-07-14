import Repository
import SwiftUI
import WidgetKit

struct NextTripAccessoryRectangularWidget: View {
    let country: CountrySnapshot
    let departureDate: Date
    let returnDate: Date

    private var countdown: NextTripCountdown {
        NextTripCountdown(departureDate: departureDate, returnDate: returnDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(country.widgetTitle, systemImage: countdown.symbolName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(countdown.displayText)
                .font(.caption.weight(.bold))
            if !countdown.isOnVacation {
                Text(departureDate, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

#if DEBUG
#Preview(as: .accessoryRectangular) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), returnDate: .now.addingTimeInterval(20 * 86_400), isPremium: true)
}
#endif
