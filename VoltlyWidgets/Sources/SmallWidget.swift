import SwiftUI
import WidgetKit

struct SmallWidget: View {
    let entry: HomeCountryEntry
    
    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: 10) {
                WidgetHeader()
                
                if let country = entry.country {
                    Text(country.flagUnicode)
                        .font(.system(size: 30))
                    
                    WidgetChips(country: country)
                    
                    WidgetPlugs(country: country, limit: 4, type: .small)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        WidgetStrings.text("widget.set.home.country")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(WidgetPalette.primaryText)

                        WidgetStrings.text("widget.empty.description")
                            .font(.caption)
                            .foregroundStyle(WidgetPalette.secondaryText)
                            .lineLimit(4)
                    }
                }
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}


#if DEBUG
#Preview(as: .systemSmall) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .systemSmall) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: nil)
}
#endif
