import SwiftUI
import WidgetKit

struct AccessoryRectangularWidget: View {
    let entry: HomeCountryEntry
    
    var countryName: String? {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: entry.country?.code ?? "") ?? entry.country?.name
    }
    
    var countryTitle: String {
        [entry.country?.flagUnicode, countryName].compactMap{ $0 }.joined(separator: " ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let country = entry.country {
                Text(countryTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text("\(country.voltage) • \(country.frequency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(country.plugTypeIDs.map { localizedPlugType($0) }.joined(separator: "  "))
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            } else {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.accent)
                    
                    VStack(alignment: .leading) {
                        Text("Voltly")
                            .font(.caption.weight(.semibold))
                        WidgetStrings.text("widget.set.home.country")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private func localizedPlugType(_ id: String) -> String {
        WidgetStrings.string("widget.plug.type", id)
    }
}


#if DEBUG
#Preview(as: .accessoryRectangular) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: .preview)
}

#Preview(as: .accessoryRectangular) {
    HomeCountryWidget()
} timeline: {
    HomeCountryEntry(date: .now, country: nil)
}
#endif
