import SwiftUI
import Repository

struct WidgetPlugs: View {
    let country: CountrySnapshot
    let limit: Int
    let type: WidgetType
    
    enum WidgetType {
        case small
        case large
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(country.plugTypeIDs.prefix(limit)), id: \.self) { plugType in
                if type == .large {
                    Text("Type \(plugType)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WidgetPalette.plugChip)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "poweroutlet.type.\(plugType.lowercased())")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(WidgetPalette.primaryText)
                }
            }
        }
    }
}

