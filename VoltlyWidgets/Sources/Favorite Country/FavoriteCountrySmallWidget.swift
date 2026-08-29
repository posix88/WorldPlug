import Repository
import SwiftUI
import WidgetKit

// MARK: - FavoriteCountrySmallWidget

struct FavoriteCountrySmallWidget: View {
    let country: CountrySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
            FavoriteCountryHeader()

            WidgetFlag(flagUnicode: country.flagUnicode, pointSize: 30)

            WidgetChips(country: country)
            WidgetPlugs(country: country, limit: 4, type: .small)
        }
        .padding(WidgetLayout.compactPadding)
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
}
#endif
