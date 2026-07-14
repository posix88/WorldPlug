import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountryMediumWidget: View {
    let country: CountrySnapshot

    private var countryName: String {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: country.code) ?? country.name
    }

    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: 10) {
                FavoriteCountryHeader()

                HStack(spacing: 12) {
                    Text(country.flagUnicode)
                        .font(.system(size: 38))

                    Text(countryName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .lineLimit(1)
                }

                WidgetChips(country: country)
                WidgetPlugs(country: country, limit: 6, type: .large)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
