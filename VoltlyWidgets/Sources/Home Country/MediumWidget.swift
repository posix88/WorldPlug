import SwiftUI
import WidgetKit

struct MediumWidget: View {
    let entry: HomeCountryEntry

    var body: some View {
        ZStack {
            WidgetBackground()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: WidgetLayout.sectionSpacing) {
                    WidgetHeader()

                    if let country = entry.country {
                        WidgetCountryIdentity(country: country)

                        WidgetChips(country: country)

                        WidgetPlugs(country: country, limit: 6, type: .large)
                    } else {
                        WidgetEmptyState()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(WidgetLayout.expandedPadding)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .systemMedium) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: nil)
}
#endif
