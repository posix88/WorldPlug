import SwiftUI
import WidgetKit

struct AccessoryInlineWidget: View {
    let entry: HomeCountryEntry
    
    var countryName: String? {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: entry.country?.code ?? "") ?? entry.country?.name
    }
    
    var countryTitle: String {
        [entry.country?.flagUnicode, countryName, entry.country?.voltage, entry.country?.frequency].compactMap{ $0 }.joined(separator: " ")
    }
    
    var body: some View {
        if entry.country != nil  {
            Text(countryTitle)
        } else {
            WidgetStrings.text("widget.empty.inline")
        }
    }
}

#if DEBUG
#Preview(as: .accessoryInline) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .accessoryInline) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: nil)
}
#endif
