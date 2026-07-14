import SwiftUI
import WidgetKit

struct AccessoryInlineWidget: View {
    let entry: HomeCountryEntry
    
    var body: some View {
        if let country = entry.country {
            Text("\(country.flagUnicode) \(country.voltage) \(country.frequency)")
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
