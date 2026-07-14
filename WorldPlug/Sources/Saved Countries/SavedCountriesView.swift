import Repository
import SwiftData
import SwiftUI

// MARK: - SavedCountriesView

struct SavedCountriesView: View {
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Query(sort: \Country.code) private var countries: [Country]

    var body: some View {
        NavigationStack {
            Group {
                if premiumEntitlement.isPremium {
                    if savedCountries.isEmpty {
                        ContentUnavailableView(
                            LocalizationKeys.savedCountriesEmptyTitle.localized,
                            systemImage: "star",
                            description: Text(LocalizationKeys.savedCountriesEmptyDescription.localized)
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: .md) {
                                ForEach(savedCountries) { country in
                                    CountryBrowserRow(country: country, compatibility: nil)
                                }
                            }
                            .padding(.horizontal, .xxl)
                            .padding(.vertical, .md)
                        }
                        .navigationDestination(for: Country.self) { country in
                            CountryDetailView(country: country)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesPremiumTitle.localized,
                        systemImage: "lock.fill",
                        description: Text(LocalizationKeys.savedCountriesPremiumDescription.localized)
                    )
                }
            }
            .navigationTitle(LocalizationKeys.savedCountriesTitle.localized)
            .background { AppMeshBackground() }
        }
    }

    private var savedCountries: [Country] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return travelPreferencesStore.preferences.savedCountryCodes.compactMap { countriesByCode[$0] }
    }
}

#if DEBUG
#Preview {
    SavedCountriesView()
}
#endif
