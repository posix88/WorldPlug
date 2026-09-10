import Analytics
import AppIntents
import Repository
import SwiftData
import SwiftUI

// MARK: - SavedCountriesView

/// Just the list of starred countries. It used to also host the trip planner and the
/// favorite-widget picker, and to be locked wholesale behind premium — the trip planner moved to
/// the Trips tab, the widget picker moved to Settings, and the premium gate moved to the *saving*
/// action (see `SavedCountryLimit`), so there is nothing left here but the list.
struct SavedCountriesView: View {
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var viewModel: SavedCountriesViewModel
    @State private var removalFeedbackTrigger = 0

    init(
        premiumEntitlement: any PremiumEntitlementProviding,
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        analyticsTracker: any AnalyticsTracker
    ) {
        _viewModel = State(
            initialValue: SavedCountriesViewModel(
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                analyticsTracker: analyticsTracker
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            content
                .navigationTitle(LocalizationKeys.savedCountriesTitle.localized)
                .background { AppMeshBackground() }
                .onAppear {
                    viewModel.updateCountries(countries)
                    viewModel.screenAppeared()
                }
                .onChange(of: countries.map(\.code)) { _, _ in
                    viewModel.updateCountries(countries)
                }
        }
        .sensoryFeedback(.success, trigger: removalFeedbackTrigger)
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: .md) {
                if viewModel.savedCountries.isEmpty {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesEmptyTitle.localized,
                        systemImage: "star",
                        description: Text(LocalizationKeys.savedCountriesEmptyDescription.localized)
                    )
                    .padding(.top, .special)
                } else {
                    ForEach(viewModel.savedCountries) { country in
                        savedCountryRow(country)
                    }

                    if let hint = viewModel.freeLimitHint {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.textLight)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, .sm)
                    }
                }
            }
            .padding(.horizontal, .xxl)
            .padding(.vertical, .md)
        }
        .swipeActionsContainer()
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityIdentifier("savedCountries.premiumContent")
        .navigationDestination(item: $viewModel.selectedCountry) { country in
            CountryDetailView(
                country: country,
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                analyticsTracker: analyticsTracker
            )
        }
    }

    private func savedCountryRow(_ country: Country) -> some View {
        Button {
            viewModel.selectedCountry = country
        } label: {
            CountrySummaryCard(
                country: country,
                compatibility: nil,
                isHomeCountry: country.code == viewModel.homeCountryCode
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("savedCountry.\(country.code)")
        .appEntityIdentifier(
            EntityIdentifier(for: CountryEntity.self, identifier: country.code)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                removeSavedCountry(code: country.code)
            } label: {
                Image(systemName: "star.slash.fill")
            }
        }
    }

    private func removeSavedCountry(code: String) {
        viewModel.removeSavedCountry(code: code)
        removalFeedbackTrigger += 1
    }
}

#if DEBUG
#Preview("Empty") {
    SavedCountriesView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
        travelPreferencesStore: PreviewTravelPreferencesStore(),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
}

#Preview("Free tier, at the limit") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: configuration)
    let codes = ["IT", "JP", "GB"]
    for code in codes {
        container.mainContext.insert(
            Country(code: code, voltage: "230V", frequency: "50Hz", flagUnicode: "🏳️")
        )
    }

    return SavedCountriesView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
        travelPreferencesStore: PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: codes)
        ),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}

#Preview("Premium") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: configuration)
    let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    container.mainContext.insert(country)

    return SavedCountriesView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
        travelPreferencesStore: PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: [country.code])
        ),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}
#endif
