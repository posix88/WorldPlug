import Analytics
import AppIntents
import Repository
import StoreKit
import SwiftData
import SwiftUI
import TipKit

// MARK: - SavedCountriesView

struct SavedCountriesView: View {
    @Environment(\.locale) private var locale
    @Environment(\.requestReview) private var requestReview
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var viewModel: SavedCountriesViewModel
    @State private var removalFeedbackTrigger = 0
    private let nextTripTip = NextTripTip()
    private let favoriteWidgetSelectorTip = FavoriteWidgetSelectorTip()

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
            savedCountriesContent
                .navigationTitle(LocalizationKeys.savedCountriesTitle.localized)
                .toolbar {
                    if viewModel.isPremium {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.presentTripEditor()
                                nextTripTip.invalidate(reason: .actionPerformed)
                            } label: {
                                Image(systemName: viewModel.nextTrip == nil ? "calendar.badge.plus" : "calendar")
                            }
                            .accessibilityLabel(LocalizationKeys.nextTripEdit.localized)
                            .popoverTip(nextTripTip, arrowEdge: .top)
                            .appTipIconTint()
                        }
                    }
                }
                .background { AppMeshBackground() }
                .onAppear {
                    viewModel.updateCountries(countries)
                    viewModel.screenAppeared()
                }
                .onChange(of: countries.map(\.code)) { _, _ in
                    viewModel.updateCountries(countries)
                }
                .sheet(isPresented: $viewModel.isTripEditorPresented) {
                    NextTripEditorView(
                        trip: viewModel.nextTrip,
                        countries: countries,
                        onSave: { trip in
                            if viewModel.saveNextTrip(trip) {
                                AppReviewPrompt.requestAfterSuccessfulAction(using: { requestReview() })
                            }
                        },
                        onDelete: viewModel.deleteNextTrip
                    )
                }
                .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                    PremiumPaywallView(source: .savedCountries)
                }
        }
        .sensoryFeedback(.success, trigger: removalFeedbackTrigger)
    }

    @ViewBuilder
    private var savedCountriesContent: some View {
        if viewModel.isPremium {
            premiumContent
        } else {
            lockedContent
        }
    }

    private var premiumContent: some View {
        ScrollView {
            LazyVStack(spacing: .md) {
                nextTripCard
                favoriteWidgetCard

                if viewModel.savedCountries.isEmpty {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesEmptyTitle.localized,
                        systemImage: "star",
                        description: Text(LocalizationKeys.savedCountriesEmptyDescription.localized)
                    )
                    .padding(.top, .special)
                } else {
                    ForEach(viewModel.savedCountries) { country in
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
                }
            }
            .padding(.horizontal, .xxl)
            .padding(.vertical, .md)
        }
        .savedCountriesSwipeActionsContainer()
        .scrollBounceBehavior(.basedOnSize)
        .navigationDestination(item: $viewModel.selectedCountry) { country in
            CountryDetailView(
                country: country,
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                analyticsTracker: analyticsTracker
            )
        }
    }

    private var lockedContent: some View {
        ScrollView {
            VStack(spacing: .xl) {
                ContentUnavailableView {
                    Label(LocalizationKeys.savedCountriesPremiumTitle.localized, systemImage: "lock.fill")
                } description: {
                    Text(LocalizationKeys.savedCountriesPremiumDescription.localized)
                }

                SavedCountriesPremiumPreview()

                Button(LocalizationKeys.premiumPaywallPurchase.localized) {
                    viewModel.isPremiumPaywallPresented = true
                }
                .buttonStyle(.glassProminent)
                .tint(.premiumTint)
                .controlSize(.regular)
            }
            .padding(.horizontal, .xxl)
            .padding(.top, .special)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var nextTripCard: some View {
        if let trip = viewModel.nextTrip,
           let country = countries.first(where: { $0.code == trip.countryCode }) {
            Button {
                viewModel.presentTripEditor()
            } label: {
                VStack(alignment: .leading, spacing: .sm) {
                    Text(LocalizationKeys.nextTripTitle.localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textLight)
                        .textCase(.uppercase)

                    Text(trip.name ?? "\(country.flagUnicode) \(country.localizedName(in: locale))")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(trip.departureDate, format: .dateTime.day().month().year())
                        .font(.subheadline)
                        .foregroundStyle(.textLight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.lg)
                .background(.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .appEntityIdentifier(
                EntityIdentifier(for: CountryEntity.self, identifier: country.code)
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteNextTrip()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private var favoriteWidgetCard: some View {
        Menu {
            Button(LocalizationKeys.favoriteWidgetNoSelection.localized) {
                viewModel.selectFavoriteWidgetCountry(code: nil)
                favoriteWidgetSelectorTip.invalidate(reason: .actionPerformed)
            }

            ForEach(viewModel.savedCountries) { country in
                Button("\(country.flagUnicode) \(country.localizedName(in: locale))") {
                    viewModel.selectFavoriteWidgetCountry(code: country.code)
                    favoriteWidgetSelectorTip.invalidate(reason: .actionPerformed)
                }
            }
        } label: {
            HStack(spacing: .md) {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(.premiumTint)

                VStack(alignment: .leading, spacing: .xxs) {
                    Text(LocalizationKeys.favoriteWidgetTitle.localized)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(favoriteWidgetCountryName)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.textLighter)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.lg)
            .background(.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(viewModel.savedCountries.isEmpty)
        .popoverTip(viewModel.savedCountries.isEmpty ? nil : favoriteWidgetSelectorTip, arrowEdge: .bottom)
        .appTipIconTint()
        .accessibilityLabel(LocalizationKeys.favoriteWidgetTitle.localized)
        .accessibilityValue(favoriteWidgetCountryName)
        .appEntityIdentifier(
            viewModel.favoriteWidgetCountry.map {
                EntityIdentifier(for: CountryEntity.self, identifier: $0.code)
            }
        )
    }

    private var favoriteWidgetCountryName: String {
        guard let country = viewModel.favoriteWidgetCountry else {
            return LocalizationKeys.favoriteWidgetNoSelection.localized
        }

        return "\(country.flagUnicode) \(country.localizedName(in: locale))"
    }

    private func deleteNextTrip() {
        viewModel.deleteNextTrip()
        removalFeedbackTrigger += 1
    }

    private func removeSavedCountry(code: String) {
        viewModel.removeSavedCountry(code: code)
        removalFeedbackTrigger += 1
    }
}

private extension View {
    @ViewBuilder
    func savedCountriesSwipeActionsContainer() -> some View {
        if #available(iOS 27.0, *) {
            swipeActionsContainer()
        } else {
            self
        }
    }
}

// MARK: - SavedCountriesPremiumPreview

private struct SavedCountriesPremiumPreview: View {
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            VStack(spacing: .md) {
                previewRow(flag: "🇯🇵", countryCode: "JP")
                previewRow(flag: "🇬🇧", countryCode: "GB")
            }
            .padding(.lg)
            .blur(radius: 4)

            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(.textLight)
                .padding(.md)
                .glassEffect(.regular, in: .circle)
        }
        .background(.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityHidden(true)
    }

    private func previewRow(flag: String, countryCode: String) -> some View {
        HStack(spacing: .md) {
            Text(flag)
                .font(.title2)

            Text(locale.localizedString(forRegionCode: countryCode) ?? countryCode)
                .font(.body.weight(.semibold))

            Spacer()

            Image(systemName: "star.fill")
                .foregroundStyle(.premiumTint)
        }
    }
}

// MARK: - NextTripTip

private struct NextTripTip: Tip {
    var title: Text {
        Text(LocalizationKeys.nextTripTipTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.nextTripTipMessage.localized)
    }

    var image: Image? {
        Image(systemName: "calendar.badge.plus")
    }
}

// MARK: - FavoriteWidgetSelectorTip

private struct FavoriteWidgetSelectorTip: Tip {
    var title: Text {
        Text(LocalizationKeys.favoriteWidgetTipTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.favoriteWidgetTipMessage.localized)
    }

    var image: Image? {
        Image(systemName: "rectangle.on.rectangle")
    }
}

#if DEBUG
#Preview("Premium locked") {
    SavedCountriesView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
        travelPreferencesStore: PreviewTravelPreferencesStore(),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
}

#Preview("Premium empty") {
    SavedCountriesView(
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
        travelPreferencesStore: PreviewTravelPreferencesStore(),
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        analyticsTracker: NoopAnalyticsTracker()
    )
}

#Preview {
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
