import Repository
import SwiftUI
import WidgetKit

// MARK: - FavoriteCountryAccessoryInlineWidget

struct FavoriteCountryAccessoryInlineWidget: View {
    let country: CountrySnapshot

    var body: some View {
        // `verbatim`: a star, a flag and two catalog-supplied ratings. Without it the literal is
        // a `LocalizedStringKey` and Xcode extracts "★ %@ %@ %@" into the widget catalog.
        Text(verbatim: "★ \(country.flagUnicode) \(country.voltage) \(country.frequency)")
    }
}

#if DEBUG
#Preview(as: .accessoryInline) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
}
#endif
