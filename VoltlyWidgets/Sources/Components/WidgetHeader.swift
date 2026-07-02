import SwiftUI

struct WidgetHeader: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "house.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.accent)

//            WidgetStrings.text("widget.home.setup")
//                .font(.caption.weight(.semibold))
//                .foregroundStyle(WidgetPalette.secondaryText)
        }
    }
}
