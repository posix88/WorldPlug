import Repository
import SwiftUI

// MARK: - OnboardingCountryRow

struct OnboardingCountryRow: View {
    let country: Country
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(country.flagUnicode)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(country.localizedName(in: locale))
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isSelected ? .yellow.opacity(0.14) : .white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.yellow.opacity(0.45), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
