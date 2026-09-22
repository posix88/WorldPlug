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
    // `locale` and `requestReview` moved down to the sections that read them. A keypath
    // `@Environment` declaration subscribes the view to that key whether or not the body
    // references it, so leaving them here would have kept re-evaluating this whole `Form` on
    // every locale change for nothing.
    @Environment(\.dismiss) private var dismiss
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
                SettingsTravelSection(viewModel: viewModel)
                SettingsWidgetsSection(viewModel: viewModel)
                SettingsPremiumSection(viewModel: viewModel)
                SettingsAboutSection(viewModel: viewModel)
                SettingsDebugSection()
            }
            .scrollContentBackground(.hidden)
            .groupedCellSurface()
            .background { AppMeshBackground() }
            .navigationTitle(LocalizationKeys.settingsTitle)
            .accessibilityIdentifier("settings.form")
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .savedCountries)
            }
            .alert(
                LocalizationKeys.settingsRestoreFailed,
                isPresented: $viewModel.isRestoreFailureAlertPresented
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss, role: .cancel) {
                    viewModel.restoreFailureMessage = nil
                }
            } message: {
                Text(viewModel.restoreFailureMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(LocalizationKeys.generalClose, systemImage: "xmark")
                    }
                    .accessibilityIdentifier("settings.done")
                }
            }
            .onAppear {
                viewModel.updateCountries(countries)
                viewModel.screenAppeared()
            }
            .onChange(of: countries.count) { _, _ in
                viewModel.updateCountries(countries)
            }
        }
    }

    // MARK: Routes

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        @Bindable var viewModel = viewModel

        switch route {
        case .homeCountryPicker:
            // `$viewModel.selectedHomeCountryCode` instead of a `Binding(get:set:)` assembled
            // here — the branching "empty means clear" logic lives on the view model as a
            // settable projection. See `SettingsViewModel.selectedHomeCountryCode`.
            CountryDestinationPickerView(
                selectedCountryCode: $viewModel.selectedHomeCountryCode,
                countries: countries,
                title: LocalizationKeys.settingsHomeCountry,
                screen: .settings,
                allowsNoSelection: true,
                noSelectionTitle: LocalizationKeys.settingsHomeCountryNone
            )

        case .favoriteWidgetPicker:
            CountryDestinationPickerView(
                selectedCountryCode: $viewModel.selectedFavoriteWidgetCountryCode,
                // Deliberately only the saved countries: the widget can't show one the user
                // hasn't starred, so offering the full catalogue here would offer a dead end.
                countries: viewModel.savedCountries,
                title: LocalizationKeys.favoriteWidgetTitle,
                screen: .settings,
                allowsNoSelection: true
            )
        }
    }
}

// MARK: - Section names

/// Each `Form` section is its own `View` type rather than a `private var … some View` on
/// `SettingsView`. A computed property is inlined into the enclosing body and shares its
/// invalidation boundary, so a restore spinner ticking used to re-evaluate the home-country row,
/// the widget row, the version string and the share link along with it.
private func settingsCountryName(_ country: Country?, locale: Locale) -> String? {
    guard let country else {
        return nil
    }

    return "\(country.flagUnicode) \(country.localizedName(in: locale))"
}

// MARK: - SettingsTravelSection

private struct SettingsTravelSection: View {
    let viewModel: SettingsViewModel
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            NavigationLink(value: SettingsRoute.homeCountryPicker) {
                LabeledContent(LocalizationKeys.settingsHomeCountry) {
                    Text(
                        settingsCountryName(viewModel.homeCountry, locale: locale)
                            ?? String(localized: LocalizationKeys.settingsHomeCountryNone)
                    )
                }
            }
            .accessibilityIdentifier("settings.homeCountry")

            if viewModel.homeCountry != nil {
                Button(LocalizationKeys.settingsHomeCountryClear, role: .destructive) {
                    viewModel.clearHomeCountry()
                }
            }
        } header: {
            Text(LocalizationKeys.settingsSectionTravel)
        } footer: {
            Text(LocalizationKeys.settingsHomeCountryFooter)
        }
        .groupedCellSurface()
    }
}

// MARK: - SettingsWidgetsSection

private struct SettingsWidgetsSection: View {
    let viewModel: SettingsViewModel
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            NavigationLink(value: SettingsRoute.favoriteWidgetPicker) {
                LabeledContent(LocalizationKeys.favoriteWidgetTitle) {
                    Text(
                        settingsCountryName(viewModel.favoriteWidgetCountry, locale: locale)
                            ?? String(localized: LocalizationKeys.favoriteWidgetNoSelection)
                    )
                }
            }
            .disabled(!viewModel.canChooseFavoriteWidgetCountry)
            .accessibilityIdentifier("settings.favoriteWidgetCountry")
        } header: {
            Text(LocalizationKeys.settingsSectionWidgets)
        } footer: {
            Text(
                viewModel.canChooseFavoriteWidgetCountry
                    ? LocalizationKeys.settingsFavoriteWidgetFooter
                    : LocalizationKeys.settingsFavoriteWidgetNeedsSaved
            )
        }
        .groupedCellSurface()
    }
}

// MARK: - SettingsPremiumSection

private struct SettingsPremiumSection: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Section {
            if viewModel.isPremium {
                Label(LocalizationKeys.settingsPremiumActive, systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.premiumTint)
            } else {
                // Just the status, not "Socket Buddy Premium — Free version": the section header
                // already carries the name, and repeating it read as a stutter on device.
                Label(LocalizationKeys.settingsPremiumInactive, systemImage: "star")
                    .foregroundStyle(.textLight)

                Button(LocalizationKeys.premiumPaywallPurchase) {
                    viewModel.presentPaywall()
                }
                .accessibilityIdentifier("settings.unlockPremium")

                SettingsRestoreButton(viewModel: viewModel)
            }
        } header: {
            Text(LocalizationKeys.settingsSectionPremium)
        } footer: {
            if viewModel.isPremium {
                Text(LocalizationKeys.settingsPremiumActiveFooter)
            }
        }
        .groupedCellSurface()
    }
}

// MARK: - SettingsRestoreButton

/// Its own type mainly so `isRestoring` — which flips twice per restore — only invalidates this
/// button, not the whole premium section.
private struct SettingsRestoreButton: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Button {
            Task { await viewModel.restorePurchases() }
        } label: {
            HStack {
                Text(LocalizationKeys.premiumPaywallRestore)

                if viewModel.isRestoring {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(viewModel.isRestoring)
        .accessibilityIdentifier("settings.restorePurchases")
    }
}

// MARK: - SettingsAboutSection

private struct SettingsAboutSection: View {
    let viewModel: SettingsViewModel
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Section(LocalizationKeys.settingsSectionAbout) {
            LabeledContent(LocalizationKeys.settingsVersion) {
                Text(viewModel.appVersion)
            }

            Button(LocalizationKeys.settingsRate) {
                requestReview()
            }

            // `ShareLink(item:)` shares a value, not a label — it needs a real `String`.
            ShareLink(item: String(localized: LocalizationKeys.settingsShareText)) {
                Text(LocalizationKeys.settingsShare)
            }
        }
        .groupedCellSurface()
    }
}

// MARK: - SettingsDebugSection

private struct SettingsDebugSection: View {
    var body: some View {
        #if DEBUG
        if AppDebugOverrides.isEnabled {
            Section(LocalizationKeys.settingsDebug) {
                Label(LocalizationKeys.settingsDebugSeededData, systemImage: "ladybug.fill")
                    .foregroundStyle(.statusCheck)
            }
            .groupedCellSurface()
        }
        #endif
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
