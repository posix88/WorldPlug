import Repository
import SwiftUI

// MARK: - CountryBrowserRowModel

struct CountryBrowserRowModel {
    let country: Country
    let isHomeCountry: Bool
    let isSavedCountry: Bool
    let isPremium: Bool
}

// MARK: - CountryBrowserRow

struct CountryBrowserRow: View {
    let model: CountryBrowserRowModel
    let compatibility: CountryCompatibilitySummary?
    let onToggleHomeCountry: (String) -> Void
    let onToggleSavedCountry: (String) -> Bool
    @State private var isPremiumPaywallPresented = false
    @State private var actionFeedbackTrigger = 0

    var body: some View {
        NavigationLink(value: model.country) {
            CountrySummaryCard(
                country: model.country,
                compatibility: compatibility,
                isHomeCountry: model.isHomeCountry
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleHomeCountry()
            } label: {
                Image(systemName: model.isHomeCountry ? "house.slash.fill" : "house.fill")
            }
            .accessibilityLabel(
                model.isHomeCountry
                    ? LocalizationKeys.homeCountryRemove.localized
                    : LocalizationKeys.homeCountrySet.localized
            )
            .tint(model.isHomeCountry ? .statusUnsafe : .voltTint)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: handleSavedCountryAction) {
                savedCountryIcon
            }
            .accessibilityLabel(savedCountryAccessibilityLabel)
            .tint(.premiumTint)
        }
        .contextMenu {
            if model.isHomeCountry {
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
        .sensoryFeedback(.selection, trigger: actionFeedbackTrigger)
    }

    private func toggleHomeCountry() {
        onToggleHomeCountry(model.country.code)
        actionFeedbackTrigger += 1
    }

    private var savedCountrySymbolName: String {
        guard model.isPremium else {
            return "star.fill"
        }

        return model.isSavedCountry ? "star.slash.fill" : "star.fill"
    }

    @ViewBuilder
    private var savedCountryIcon: some View {
        Image(systemName: savedCountrySymbolName)
            .overlay(alignment: .bottomTrailing) {
                if !model.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white, .premiumTint)
                }
            }
    }

    private var savedCountryAccessibilityLabel: String {
        guard model.isPremium else {
            return LocalizationKeys.premiumPaywallCountrySaveMessage.localized
        }

        return model.isSavedCountry
            ? LocalizationKeys.savedCountriesRemove.localized
            : LocalizationKeys.savedCountriesAdd.localized
    }

    private func handleSavedCountryAction() {
        guard onToggleSavedCountry(model.country.code) else {
            isPremiumPaywallPresented = true
            return
        }

        actionFeedbackTrigger += 1
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
        CountryBrowserRow(
            model: CountryBrowserRowModel(
                country: country,
                isHomeCountry: false,
                isSavedCountry: false,
                isPremium: true
            ),
            compatibility: .compatible,
            onToggleHomeCountry: { _ in },
            onToggleSavedCountry: { _ in true }
        )
        .padding(.xxl)
        .modelContainer(container)
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "GB", plugTypeIDs: ["G"]))
    }
}
#endif
