import Repository
import SwiftUI
import WidgetKit

struct NextTripMediumWidget: View {
    let homeCountry: CountrySnapshot?
    let country: CountrySnapshot
    let departureDate: Date
    let returnDate: Date

    private var countdown: NextTripCountdown {
        NextTripCountdown(departureDate: departureDate, returnDate: returnDate)
    }
    private var compatibility: NextTripCompatibility {
        NextTripCompatibility(homeCountry: homeCountry, destination: country)
    }

    var body: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: WidgetLayout.sectionSpacing) {
                HStack(alignment: .top) {
                    Label(WidgetStrings.string(countdown.titleKey), systemImage: countdown.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.accent)

                    Spacer()

                    Text(countdown.displayText)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WidgetPalette.frequency)
                }

                WidgetCountryIdentity(country: country)
                NextTripCompactCompatibility(compatibility: compatibility)
            }
            .padding(WidgetLayout.expandedPadding)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), returnDate: .now.addingTimeInterval(20 * 86_400), isPremium: true)
}
#endif
