import Repository
import SwiftUI
import WidgetKit

struct FavoriteCountryAccessoryInlineWidget: View {
    let country: CountrySnapshot

    private var countryName: String {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: country.code) ?? country.name
    }

    var body: some View {
        Text("★ \(country.flagUnicode) \(countryName) \(country.voltage) \(country.frequency)")
    }
}
