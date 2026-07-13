import SwiftUI

struct WidgetHeader: View {
    var body: some View {
        Image(systemName: "house.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(WidgetPalette.accent)
    }
}
