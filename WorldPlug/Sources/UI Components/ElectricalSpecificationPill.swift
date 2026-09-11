import SwiftUI

struct ElectricalSpecificationPill: View {
    let icon: SFSymbols
    /// `LocalizedStringResource`: this is user-facing text, so it stays unresolved until the
    /// label is actually rendered and keeps honouring the `\.locale` environment override.
    let label: LocalizedStringResource
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            icon.image
                .imageScale(.small)

            // No `lineLimit(1)`: at accessibility text sizes this pill is narrower than its own
            // value, and a single line truncated the voltage away entirely — "⚡ …" instead of
            // "⚡ 220V". Wrapping is ugly; hiding the number the whole app exists to show is worse.
            Text(value)
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

#Preview {
    ElectricalSpecificationPill(
        icon: .boltCircleFill,
        label: "Voltage",
        value: "230V",
        color: .voltTint
    )
    .padding()
}
