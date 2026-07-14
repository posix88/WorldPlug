import Repository
import SwiftUI
import WidgetKit

struct NextTripLargeWidget: View {
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
        ZStack(alignment: .top) {
            WidgetBackground()

            VStack(alignment: .leading, spacing: WidgetLayout.sectionSpacing) {
                HStack(alignment: .top) {
                    Label(WidgetStrings.string(countdown.titleKey), systemImage: countdown.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.accent)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(countdown.displayText)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(WidgetPalette.frequency)
                        if !countdown.isOnVacation {
                            Text(departureDate, format: .dateTime.day().month(.wide).year())
                                .font(.caption2)
                                .foregroundStyle(WidgetPalette.secondaryText)
                        }
                    }
                }

                WidgetCountryIdentity(country: country)

                WidgetChips(country: country)

                WidgetPlugList(country: country, limit: 3)

                if country.plugTypeIDs.count > 3,
                   let countryDetailURL = WidgetDeepLink.country(country.code) {
                    Link(destination: countryDetailURL) {
                        Label(WidgetStrings.string("widget.more"), systemImage: "ellipsis.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetPalette.accent)
                    }
                }
                
                Spacer()

                NextTripCompatibilityCard(compatibility: compatibility)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WidgetLayout.expandedPadding)
        }
        .containerBackground(for: .widget) { Color.clear }
    }

}

#if DEBUG
#Preview(as: .systemLarge) {
    NextTripWidget()
} timeline: {
    NextTripEntry(
        date: .now,
        homeCountry: .preview,
        country: .preview,
        departureDate: .now.addingTimeInterval(12 * 86_400),
        returnDate: .now.addingTimeInterval(20 * 86_400),
        isPremium: true
    )
}
#endif
