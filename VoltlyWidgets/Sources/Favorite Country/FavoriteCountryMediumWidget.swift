import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountryMediumWidget: View {
    let country: CountrySnapshot

    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: WidgetLayout.sectionSpacing) {
                FavoriteCountryHeader()

                WidgetCountryIdentity(country: country)

                WidgetChips(country: country)
                WidgetPlugs(country: country, limit: 6, type: .large)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WidgetLayout.expandedPadding)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    FavoriteCountryWidget()
} timeline: {
    FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
}
#endif
