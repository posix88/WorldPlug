import SwiftUI

struct WidgetEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: WidgetLayout.compactSpacing) {
            WidgetStrings.text("widget.set.home.country")
                .font(.headline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText)

            WidgetStrings.text("widget.empty.description")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText)
                .lineLimit(4)
        }
    }
}
