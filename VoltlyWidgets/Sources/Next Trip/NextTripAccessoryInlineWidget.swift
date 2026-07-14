import Repository
import SwiftUI
import WidgetKit

struct NextTripAccessoryInlineWidget: View {
    let country: CountrySnapshot
    let departureDate: Date
    let returnDate: Date

    private var countdown: NextTripCountdown {
        NextTripCountdown(departureDate: departureDate, returnDate: returnDate)
    }

    var body: some View {
        Label("\(country.flagUnicode) \(countdown.displayText)", systemImage: countdown.symbolName)
    }
}

#if DEBUG
#Preview(as: .accessoryInline) {
    NextTripWidget()
} timeline: {
    NextTripEntry(date: .now, homeCountry: .preview, country: .preview, departureDate: .now.addingTimeInterval(12 * 86_400), returnDate: .now.addingTimeInterval(20 * 86_400), isPremium: true)
}
#endif
