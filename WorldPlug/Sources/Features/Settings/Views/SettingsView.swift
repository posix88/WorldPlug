import Analytics
import Repository
import StoreKit
import SwiftData
import SwiftUI

// MARK: - SettingsView

/// Presented as a full-screen cover from the Countries tab's gear. Full-screen rather than a
/// half-sheet because it pushes its own sub-screens (the two country pickers) and because it is
/// where settings will keep accumulating.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var viewModel: SettingsViewModel

    init(
        premiumEntitlement: any PremiumEntitlementProviding,
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        analyticsTracker: any AnalyticsTracker
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                analyticsTracker: analyticsTracker
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.navigationPath) {
            Form {
                travelSection
                widgetsSection
                premiumSection
                aboutSection
                debugSection
            }
            .navigationTitle(LocalizationKeys.settingsTitle.localized)
            .accessibilityIdentifier("settings.form")
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .savedCountries)
            }
            .alert(
                LocalizationKeys.settingsRestoreFailed.localized,
                isPresented: Binding(
                    get: { viewModel.restoreFailureMessage != nil },
                    set: { if !$0 {
                        viewModel.restoreFailureMessage = nil
                    } }
                )
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss.localized, role: .cancel) {
                    viewModel.restoreFailureMessage = nil
                }
            } message: {
                Text(viewModel.restoreFailureMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKeys.settingsDone.localized) { dismiss() }
                        .accessibilityIdentifier("settings.done")
                }
            }
            .onAppear {
                viewModel.updateCountries(countries)
                viewModel.screenAppeared()
            }
            .onChange(of: countries.map(\.code)) { _, _ in
                viewModel.updateCountries(countries)
            }
        }
    }

    // MARK: Sections

    private var travelSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.homeCountryPicker) {
                LabeledContent(LocalizationKeys.settingsHomeCountry.localized) {
                    Text(name(of: viewModel.homeCountry) ?? LocalizationKeys.settingsHomeCountryNone.localized)
                }
            }
            .accessibilityIdentifier("settings.homeCountry")

            if viewModel.homeCountry != nil {
                Button(LocalizationKeys.settingsHomeCountryClear.localized, role: .destructive) {
                    viewModel.clearHomeCountry()
                }
            }
        } header: {
            Text(LocalizationKeys.settingsSectionTravel.localized)
        } footer: {
            Text(LocalizationKeys.settingsHomeCountryFooter.localized)
        }
    }

    private var widgetsSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.favoriteWidgetPicker) {
                LabeledContent(LocalizationKeys.favoriteWidgetTitle.localized) {
                    Text(
                        name(of: viewModel.favoriteWidgetCountry)
                            ?? LocalizationKeys.favoriteWidgetNoSelection.localized
                    )
                }
            }
            .disabled(!viewModel.canChooseFavoriteWidgetCountry)
            .accessibilityIdentifier("settings.favoriteWidgetCountry")
        } header: {
            Text(LocalizationKeys.settingsSectionWidgets.localized)
        } footer: {
            Text(
                viewModel.canChooseFavoriteWidgetCountry
                    ? LocalizationKeys.settingsFavoriteWidgetFooter.localized
                    : LocalizationKeys.settingsFavoriteWidgetNeedsSaved.localized
            )
        }
    }

    @ViewBuilder
    private var premiumSection: some View {
        Section {
            if viewModel.isPremium {
                Label(LocalizationKeys.settingsPremiumActive.localized, systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.premiumTint)
            } else {
                // Just the status, not "Socket Buddy Premium — Free version": the section header
                // already carries the name, and repeating it read as a stutter on device.
                Label(LocalizationKeys.settingsPremiumInactive.localized, systemImage: "star")
                    .foregroundStyle(.textLight)

                Button(LocalizationKeys.premiumPaywallPurchase.localized) {
                    viewModel.presentPaywall()
                }
                .accessibilityIdentifier("settings.unlockPremium")

                restoreButton
            }
        } header: {
            Text(LocalizationKeys.settingsSectionPremium.localized)
        } footer: {
            if viewModel.isPremium {
                Text(LocalizationKeys.settingsPremiumActiveFooter.localized)
            }
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await viewModel.restorePurchases() }
        } label: {
            HStack {
                Text(LocalizationKeys.premiumPaywallRestore.localized)

                if viewModel.isRestoring {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(viewModel.isRestoring)
        .accessibilityIdentifier("settings.restorePurchases")
    }

    private var aboutSection: some View {
        Section(LocalizationKeys.settingsSectionAbout.localized) {
            LabeledContent(LocalizationKeys.settingsVersion.localized) {
                Text(viewModel.appVersion)
            }

            Button(LocalizationKeys.settingsRate.localized) {
                requestReview()
            }

            ShareLink(item: LocalizationKeys.settingsShareText.localized) {
                Text(LocalizationKeys.settingsShare.localized)
            }
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        #if DEBUG
        if AppDebugOverrides.isEnabled {
            Section(LocalizationKeys.settingsDebug.localized) {
                Label(LocalizationKeys.settingsDebugSeededData.localized, systemImage: "ladybug.fill")
                    .foregroundStyle(.statusCheck)
            }
        }
        #endif
    }

    // MARK: Routes

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        @Bindable var viewModel = viewModel

        switch route {
        case .homeCountryPicker:
            CountryDestinationPickerView(
                selectedCountryCode: Binding(
                    get: { viewModel.homeCountryCode },
                    set: { code in
                        if code.isEmpty {
                            viewModel.clearHomeCountry()
                        } else {
                            viewModel.setHomeCountry(code: code)
                        }
                    }
                ),
                countries: countries,
                title: LocalizationKeys.settingsHomeCountry.localized,
                screen: .settings,
                allowsNoSelection: true,
                noSelectionTitle: LocalizationKeys.settingsHomeCountryNone.localized
            )

        case .favoriteWidgetPicker:
            CountryDestinationPickerView(
                selectedCountryCode: Binding(
                    get: { viewModel.favoriteWidgetCountry?.code ?? "" },
                    set: { viewModel.selectFavoriteWidgetCountry(code: $0.isEmpty ? nil : $0) }
                ),
                // Deliberately only the saved countries: the widget can't show one the user
                // hasn't starred, so offering the full catalogue here would offer a dead end.
                countries: viewModel.savedCountries,
                title: LocalizationKeys.favoriteWidgetTitle.localized,
                screen: .settings,
                allowsNoSelection: true
            )
        }
    }

    private func name(of country: Country?) -> String? {
        guard let country else {
            return nil
        }

        return "\(country.flagUnicode) \(country.localizedName(in: locale))"
    }
}

#if DEBUG
#Preview("Free") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: configuration)
    let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
    container.mainContext.insert(italy)

    return SettingsView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
        travelPreferencesStore: PreviewTravelPreferencesStore(),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}

#Preview("Premium, with a saved country") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: configuration)
    let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
    container.mainContext.insert(japan)

    return SettingsView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
        travelPreferencesStore: PreviewTravelPreferencesStore(
            preferences: TravelPreferences(
                savedCountryCodes: ["JP"],
                favoriteWidgetCountryCode: "JP"
            )
        ),
        homeCountryViewModel: PreviewHomeCountryViewModel(homeCountryCode: "JP"),
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}
#endif
