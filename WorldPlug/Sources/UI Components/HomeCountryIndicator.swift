import SwiftUI

// MARK: - HomeCountryIndicator

struct HomeCountryIndicator: View {
    var body: some View {
        Image(systemName: "house.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.voltTint)
            .accessibilityLabel(LocalizationKeys.homeCountryBadge.localized)
    }
}
