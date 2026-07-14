import SwiftUI
import WidgetKit

struct SmallWidget: View {
    let entry: HomeCountryEntry
    
    var body: some View {
        ZStack {
            WidgetBackground()

            VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
                WidgetHeader()
                
                if let country = entry.country {
                    Text(country.flagUnicode)
                        .font(.system(size: 30))

                    WidgetChips(country: country)

                    WidgetPlugs(country: country, limit: 4, type: .small)
                } else {
                    WidgetEmptyState()
                }
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
