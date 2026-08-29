import Repository
import SwiftUI
import WidgetKit

// MARK: - NextTripSmallWidget

struct NextTripSmallWidget: View {
    let country: CountrySnapshot
    let departureDate: Date
    let returnDate: Date

    private var countdown: NextTripCountdown {
        NextTripCountdown(departureDate: departureDate, returnDate: returnDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
            Image(systemName: countdown.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.accent)

            WidgetFlag(flagUnicode: country.flagUnicode, pointSize: 34)

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
        .containerBackground(for: .widget) { WidgetBackground() }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    NextTripWidget()
} timeline: {
    NextTripEntry(
        date: .now,
        homeCountry: .preview,
        country: .preview,
        departureDate: .now.addingTimeInterval(12 * 86400),
        returnDate: .now.addingTimeInterval(20 * 86400),
        isPremium: true
    )
}
#endif
