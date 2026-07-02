import Repository
import SwiftUI

// MARK: - HomeCountryBannerView

/// A contextual banner that appears at the top of the countries list when a home country is set.
/// Reminds the user which country their plug compatibility is being compared against.
struct HomeCountryBannerView: View {
    let country: Country
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: .lg) {
            Image(systemName: "house.fill")
                .font(.title3)
                .foregroundStyle(.voltTint)

            VStack(alignment: .leading, spacing: .xxs) {
                Text(LocalizationKeys.homeCountryComparingWith.localized)
                    .font(.caption)
                    .foregroundStyle(.textLight)

                Text("\(country.flagUnicode)  \(country.name)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textRegular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: .xs)

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.textLighter)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizationKeys.homeCountryRemove.localized)
        }
        .padding(.horizontal, .xl)
        .padding(.vertical, .lg)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.cardSurface.opacity(0.68))
                .fill(.thinMaterial)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.voltTint.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .voltTint.opacity(0.16), radius: 14, x: 0, y: 4)
        .shadow(color: .voltTint.opacity(0.08), radius: 4, x: 0, y: 0)
    }
}

#if DEBUG
#Preview("Light") {
    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    return HomeCountryBannerView(country: country, onClear: {})
        .padding(.xxl)
}

#Preview("Dark") {
    let country = Country(code: "AE", voltage: "220V", frequency: "50Hz", flagUnicode: "🇦🇪")
    return HomeCountryBannerView(country: country, onClear: {})
        .padding(.xxl)
        .preferredColorScheme(.dark)
}
#endif
