import Repository
import SwiftUI
import WidgetKit

struct NextTripSmallWidget: View {
    let country: CountrySnapshot
    let departureDate: Date
    let returnDate: Date

    private var countdown: NextTripCountdown {
        NextTripCountdown(departureDate: departureDate, returnDate: returnDate)
    }

    var body: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                Image(systemName: countdown.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.accent)

                Text(country.flagUnicode)
                    .font(.system(size: 34))

                Text(countdown.shortDisplayText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WidgetPalette.primaryText)

                if !countdown.isOnVacation {
                    Text(departureDate, format: .dateTime.day().month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WidgetLayout.compactPadding)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), returnDate: .now.addingTimeInterval(20 * 86_400), isPremium: true)
}
#endif
