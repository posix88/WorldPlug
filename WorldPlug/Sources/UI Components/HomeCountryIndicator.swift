import SwiftUI

// MARK: - HomeCountryIndicator

struct HomeCountryIndicator: View {
    var body: some View {
        Image(systemName: "house.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(.voltTint, in: Circle())
            .accessibilityLabel(LocalizationKeys.homeCountryBadge.localized)
    }
}
