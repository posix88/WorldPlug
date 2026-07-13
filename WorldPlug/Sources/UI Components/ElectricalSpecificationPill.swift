import SwiftUI

struct ElectricalSpecificationPill: View {
    let icon: SFSymbols
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            icon.image
                .imageScale(.small)

            Text(value)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, .xs)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .roundedCorner(radius: 5)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
