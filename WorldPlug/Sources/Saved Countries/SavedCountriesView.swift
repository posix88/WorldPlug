import SwiftUI

// MARK: - SavedCountriesView

struct SavedCountriesView: View {
    @Environment(\.premiumEntitlement) private var premiumEntitlement

    var body: some View {
        NavigationStack {
            Group {
                if premiumEntitlement.isPremium {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesEmptyTitle.localized,
                        systemImage: "star",
                        description: Text(LocalizationKeys.savedCountriesEmptyDescription.localized)
                    )
                } else {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesPremiumTitle.localized,
                        systemImage: "lock.fill",
                        description: Text(LocalizationKeys.savedCountriesPremiumDescription.localized)
                    )
                }
            }
            .navigationTitle(LocalizationKeys.savedCountriesTitle.localized)
        }
    }
}

#if DEBUG
#Preview {
    SavedCountriesView()
}
#endif
