import Repository
import SwiftUI
import WidgetKit

struct NextTripAccessoryInlineWidget: View {
    let country: CountrySnapshot
    let departureDate: Date

    private var countdown: NextTripCountdown { NextTripCountdown(departureDate: departureDate) }

    var body: some View {
        Label("\(country.flagUnicode) \(countdown.displayText)", systemImage: "airplane.departure")
    }
}

#if DEBUG
#Preview(as: .accessoryInline) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), isPremium: true)
}
#endif
