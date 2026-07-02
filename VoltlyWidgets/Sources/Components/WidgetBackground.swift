import SwiftUI

struct WidgetBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        WidgetPalette.backgroundTop,
                        WidgetPalette.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(WidgetPalette.border, lineWidth: 1)
            }
            .shadow(color: WidgetPalette.glow.opacity(0.18), radius: 18, x: 0, y: 8)
            .shadow(color: WidgetPalette.glow.opacity(0.08), radius: 6, x: 0, y: 0)
    }
}
