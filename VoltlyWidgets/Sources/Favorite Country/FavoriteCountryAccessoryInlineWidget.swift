import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountryAccessoryInlineWidget: View {
    let country: CountrySnapshot

    var body: some View {
        Text("★ \(country.flagUnicode) \(country.voltage) \(country.frequency)")
    }
}

#if DEBUG
#Preview(as: .accessoryInline) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
}
#endif
