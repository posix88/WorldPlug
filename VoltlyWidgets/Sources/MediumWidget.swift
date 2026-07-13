import SwiftUI
import WidgetKit

struct MediumWidget: View {
    let entry: HomeCountryEntry

    var countryName: String? {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: entry.country?.code ?? "") ?? entry.country?.name
    }
    
    var body: some View {
        ZStack {
            WidgetBackground()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    WidgetHeader()

                    if let country = entry.country {
                        HStack(spacing: 12) {
                            Text(country.flagUnicode)
                                .font(.system(size: 38))

                            VStack(alignment: .leading, spacing: 4) {
                                if let countryName {
                                    Text(countryName)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(WidgetPalette.primaryText)
                                        .lineLimit(1)
                                }
                            }
                        }

                        WidgetChips(country: country)

                        WidgetPlugs(country: country, limit: 6, type: .large)
                    } else {
                        WidgetEmptyState()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(18)
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
