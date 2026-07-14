import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountrySmallWidget: View {
    let country: CountrySnapshot

    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: 10) {
                FavoriteCountryHeader()

                Text(country.flagUnicode)
                    .font(.system(size: 30))

                WidgetChips(country: country)
                WidgetPlugs(country: country, limit: 4, type: .small)
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
