import Repository
import SwiftUI

// MARK: - HomeCountryBannerView

/// A contextual banner that appears at the top of the countries list when a home country is set.
/// Reminds the user which country their plug compatibility is being compared against.
struct HomeCountryBannerView: View {
    let country: Country
    let onChange: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: .lg) {
            // Subtractive at accessibility sizes: the house icon goes — the caption already says
            // what the banner is — and the text takes the width it was using. Squeezed into the
            // middle of a three-column row the label wrapped over six lines and still truncated,
            // pushing the country list itself off screen.
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "house.fill")
                    .font(.title3)
                    .foregroundStyle(.voltTint)
            }

            HomeCountryBannerLabel(
                flag: country.flagUnicode,
                name: country.localizedName(in: locale)
            )

            Spacer(minLength: .xs)

            Button(action: onChange) {
                HStack(spacing: .xxs) {
                    Text(LocalizationKeys.homeCountryChange)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.voltTint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizationKeys.homeCountryChange)
        }
        .padding(.horizontal, .xl)
        .padding(.vertical, .lg)
        .glassEffect(.regular.tint(.voltTint.opacity(0.14)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.voltTint.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .voltTint.opacity(0.16), radius: 14, x: 0, y: 4)
        .shadow(color: .voltTint.opacity(0.08), radius: 4, x: 0, y: 0)
    }
}

/// The persistent counterpart to `HomeCountryBannerView`: it gives the Countries tab a direct
/// way to establish comparisons after the user has cleared their home country.
struct HomeCountrySetupBannerView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .lg) {
                Image(systemName: "house.fill")
                    .font(.title3)
                    .foregroundStyle(.voltTint)
                    .frame(width: DesignTokens.Size.smallIcon)

                VStack(alignment: .leading, spacing: .xxs) {
                    Text(LocalizationKeys.homeCountrySetupTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(LocalizationKeys.homeCountrySetupDescription)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .xs)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.voltTint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .xl)
        .padding(.vertical, .lg)
        .glassEffect(.regular.tint(.voltTint.opacity(0.14)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.voltTint.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .voltTint.opacity(0.16), radius: 14, x: 0, y: 4)
        .accessibilityLabel(LocalizationKeys.homeCountrySetupTitle)
        .accessibilityHint(LocalizationKeys.homeCountrySetupDescription)
    }
}

// MARK: - HomeCountryBannerLabel

private struct HomeCountryBannerLabel: View {
    let flag: String
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: .xxs) {
            Text(LocalizationKeys.homeCountryComparingWith)
                .font(.caption)
                .foregroundStyle(.textLight)
                .fixedSize(horizontal: false, vertical: true)

            // Neither `lineLimit(1)` nor `minimumScaleFactor`: capping the line truncated longer
            // country names ("United Kingdom" → "Unite…"), and scaling the text down is the
            // opposite of what someone who raised their text size asked for.
            Text(verbatim: "\(flag)  \(name)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.textRegular)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


#if DEBUG
#Preview("Light") {
    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    return HomeCountryBannerView(country: country, onChange: {})
        .padding(.xxl)
}

#Preview("Dark") {
    let country = Country(code: "AE", voltage: "220V", frequency: "50Hz", flagUnicode: "🇦🇪")
    return HomeCountryBannerView(country: country, onChange: {})
        .padding(.xxl)
        .preferredColorScheme(.dark)
}
#endif
