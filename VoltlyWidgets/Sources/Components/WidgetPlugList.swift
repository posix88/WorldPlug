import Repository
import SwiftUI
import WidgetKit

struct WidgetPlugList: View {
    let country: CountrySnapshot
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(country.plugTypeIDs.prefix(limit)), id: \.self) { plugType in
                HStack(spacing: 8) {
                    Image(systemName: "poweroutlet.type.\(plugType.lowercased())")
                        .foregroundStyle(WidgetPalette.primaryText)
                        .frame(width: 20)

                    Text(WidgetStrings.string("widget.plug.type", plugType))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                }
            }
        }
    }
}
