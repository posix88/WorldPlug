import SwiftUI
import Repository

struct WidgetChips: View {
    let country: CountrySnapshot
    
    var body: some View {
        HStack(spacing: 6) {
            infoChip(systemName: "bolt.fill", text: country.voltage, tint: WidgetPalette.accent)
            infoChip(systemName: "waveform", text: country.frequency, tint: WidgetPalette.frequency)
        }
    }
    
    private func infoChip(systemName: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

