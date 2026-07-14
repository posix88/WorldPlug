import Repository
import SwiftUI

extension CountrySnapshot {
    var widgetLocalizedName: String {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: code) ?? name
    }

    var widgetTitle: String {
        "\(flagUnicode) \(widgetLocalizedName)"
    }
}

struct WidgetCountryIdentity: View {
    let country: CountrySnapshot

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagUnicode)
                .font(.system(size: 38))

            Text(country.widgetLocalizedName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText)
                .lineLimit(1)
        }
    }
}
