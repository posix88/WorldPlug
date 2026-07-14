import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountrySmallWidget: View {
    let country: CountrySnapshot

    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                FavoriteCountryHeader()

                Text(country.flagUnicode)
                    .font(.system(size: 30))

                WidgetChips(country: country)
                WidgetPlugs(country: country, limit: 4, type: .small)
            }
            .padding(WidgetLayout.compactPadding)
        }
        .containerBackground(for: .widget) {
            Color.clear
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
