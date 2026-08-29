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

// MARK: - WidgetCountryIdentity

struct WidgetCountryIdentity: View {
    let country: CountrySnapshot

    var body: some View {
        HStack(spacing: 12) {
            WidgetFlag(flagUnicode: country.flagUnicode, pointSize: 38)

            Text(country.widgetLocalizedName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText)
                .lineLimit(1)
        }
    }
}
