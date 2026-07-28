import Repository
import SwiftUI

// MARK: - CountryBrowserRow

struct CountryBrowserRow: View {
    let country: Country
    let compatibility: CountryCompatibilitySummary?

    @Environment(\.homeCountryViewModel) private var homeViewModel
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @State private var isPremiumPaywallPresented = false

    private var isHomeCountry: Bool {
        country.code == homeViewModel.homeCountryCode
    }

    private var isSavedCountry: Bool {
        travelPreferencesStore.isSavedCountry(code: country.code)
    }

    var body: some View {
        NavigationLink(value: country) {
            CountrySummaryCard(
                country: country,
                compatibility: compatibility,
                isHomeCountry: isHomeCountry
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                toggleHomeCountry()
            } label: {
                Image(systemName: isHomeCountry ? "house.slash.fill" : "house.fill")
            }
            .accessibilityLabel(
                isHomeCountry
                    ? LocalizationKeys.homeCountryRemove.localized
                    : LocalizationKeys.homeCountrySet.localized
            )
            .tint(isHomeCountry ? .statusUnsafe : .voltTint)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: handleSavedCountryAction) {
                savedCountryIcon
            }
            .accessibilityLabel(savedCountryAccessibilityLabel)
            .tint(.premiumTint)
        }
        .contextMenu {
            if isHomeCountry {
                Button(role: .destructive) {
                    toggleHomeCountry()
                } label: {
                    Label(LocalizationKeys.homeCountryRemove.localized, systemImage: "house.fill")
                }
            } else {
                Button {
                    toggleHomeCountry()
                } label: {
                    Label(LocalizationKeys.homeCountrySet.localized, systemImage: "house.fill")
                }
            }

            Button(action: handleSavedCountryAction) {
                Label(savedCountryAccessibilityLabel, systemImage: savedCountrySymbolName)
            }
        }
        .sheet(isPresented: $isPremiumPaywallPresented) {
            PremiumPaywallView(source: .countryDetailSave)
        }
    }

    private func toggleHomeCountry() {
        if isHomeCountry {
            homeViewModel.clearHome()
        } else {
            homeViewModel.setHome(code: country.code)
        }
    }

    private var savedCountrySymbolName: String {
        guard premiumEntitlement.isPremium else { return "star.fill" }
        return isSavedCountry ? "star.slash.fill" : "star.fill"
    }

    @ViewBuilder
    private var savedCountryIcon: some View {
        Image(systemName: savedCountrySymbolName)
            .overlay(alignment: .bottomTrailing) {
                if !premiumEntitlement.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white, .premiumTint)
                }
            }
    }

    private var savedCountryAccessibilityLabel: String {
        guard premiumEntitlement.isPremium else {
            return LocalizationKeys.premiumPaywallCountrySaveMessage.localized
        }
        return isSavedCountry
            ? LocalizationKeys.savedCountriesRemove.localized
            : LocalizationKeys.savedCountriesAdd.localized
    }

    private func handleSavedCountryAction() {
        guard premiumEntitlement.isPremium else {
            isPremiumPaywallPresented = true
            return
        }
        travelPreferencesStore.toggleSavedCountry(code: country.code)
    }
}

#if DEBUG
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)
    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    container.mainContext.insert(country)
    country.plugs = [
        Plug(
            id: "C",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "CEE 7/16")
        ),
        Plug(
            id: "F",
            images: [],
            specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "CEE 7/4")
        )
    ]

    return NavigationStack {
        CountryBrowserRow(country: country, compatibility: .compatible)
            .padding(.xxl)
            .modelContainer(container)
            .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "GB", plugTypeIDs: ["G"]))
    }
}
#endif
