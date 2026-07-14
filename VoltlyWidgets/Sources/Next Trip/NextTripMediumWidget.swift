import Repository
import SwiftUI
import WidgetKit

struct NextTripMediumWidget: View {
    let homeCountry: CountrySnapshot?
    let country: CountrySnapshot
    let departureDate: Date

    private var countdown: NextTripCountdown { NextTripCountdown(departureDate: departureDate) }
    private var compatibility: NextTripCompatibility {
        NextTripCompatibility(homeCountry: homeCountry, destination: country)
    }

    var body: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: WidgetLayout.sectionSpacing) {
                HStack(alignment: .top) {
                    Label(WidgetStrings.string("widget.next.trip.label"), systemImage: "airplane.departure")
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
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), isPremium: true)
}
#endif
