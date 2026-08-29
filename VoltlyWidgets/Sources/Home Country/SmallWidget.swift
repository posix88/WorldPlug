import SwiftUI
import WidgetKit

// MARK: - SmallWidget

struct SmallWidget: View {
    let entry: HomeCountryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
            WidgetHeader()

            if let country = entry.country {
                WidgetFlag(flagUnicode: country.flagUnicode, pointSize: 30)

                WidgetChips(country: country)

                WidgetPlugs(country: country, limit: 4, type: .small)
            } else {
                WidgetEmptyState()
            }
        }
        .padding(WidgetLayout.compactPadding)
        .containerBackground(for: .widget) {
            WidgetBackground()
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
