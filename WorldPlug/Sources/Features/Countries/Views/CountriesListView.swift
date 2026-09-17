import Analytics
import Combine
import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - CountriesListView

struct CountriesListView<ViewModel: CountriesListViewModelType>: View {
    @State private var viewModel: ViewModel
    @Binding private var deepLinkedCountryCode: String?
    @State private var hasScheduledInitialCatalogLoad = false
    @Environment(\.locale) private var locale
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @State private var isSettingsPresented = false
    private var compatibilityFilterTip: CompatibilityFilterTip? {
        AppDebugOverrides.isEnabled ? nil : CompatibilityFilterTip()
    }

    init(
        viewModel: ViewModel,
        deepLinkedCountryCode: Binding<String?> = .constant(nil)
    ) {
        _viewModel = State(initialValue: viewModel)
        _deepLinkedCountryCode = deepLinkedCountryCode
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.navigationPath) {
            // Both subviews take the view model itself rather than a fan-out of values and
            // closures. Forwarding `viewModel.rowModel`, `viewModel.handleHomeCountryAction` and
            // `viewModel.toggleSavedCountry` as function values made both views — and every row
            // under them — compare as changed on every pass of this body, because SwiftUI has no
            // reliable way to compare closures. Passing the reference lets Observation scope each
            // subview's invalidation to the properties it actually reads, and drops
            // `displayedCountries`, `compatibilitySummaries` and `canSaveMoreCountries` out of
            // *this* body's dependency set — it no longer re-runs when the catalog is re-filtered.
            CountryResultsView(viewModel: viewModel)
                .background { AppMeshBackground() }
                .scrollContentBackground(.hidden)
                .safeAreaBar(edge: .top, spacing: 0) {
                    CountriesListCompatibilityHeader(
                        viewModel: viewModel,
                        tip: compatibilityFilterTip
                    )
                    .background {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask {
                                LinearGradient(
                                    colors: [.black, .black.opacity(0.8), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .ignoresSafeArea(edges: .top)
                    }
                }
                .searchable(
                    text: $viewModel.searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(LocalizationKeys.searchCountriesPlaceholder)
                )
                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                    guard oldValue != newValue else {
                        return
                    }

                    viewModel.search(query: newValue, locale: locale)
                }
                .onChange(of: locale.identifier) { _, _ in
                    viewModel.localeChanged(locale)
                }
                .onAppear {
                    guard !hasScheduledInitialCatalogLoad else {
                        viewModel.screenAppeared(locale: locale)
                        openDeepLinkedCountryIfNeeded()
                        return
                    }

                    // The first fetch, localized sort and compatibility pass cover the whole
                    // catalog. Let the splash fade settle before they occupy the main actor.
                    hasScheduledInitialCatalogLoad = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        guard !Task.isCancelled else {
                            return
                        }

                        viewModel.screenAppeared(locale: locale)
                        openDeepLinkedCountryIfNeeded()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Repository.catalogDidRefreshNotification)) { _ in
                    viewModel.reloadCatalog(locale: locale)
                }
                .onChange(of: deepLinkedCountryCode) { _, _ in
                    openDeepLinkedCountryIfNeeded()
                }
                .onChange(of: viewModel.homeCountry?.code) { _, _ in
                    viewModel.homeCountryChanged()
                }
                .alert(
                    homeCountryConfirmationTitle,
                    isPresented: $viewModel.isHomeCountryConfirmationPresented
                ) {
                    if viewModel.isPendingHomeCountryRemoval {
                        Button(LocalizationKeys.homeCountryRemove, role: .destructive) {
                            viewModel.confirmHomeCountryAction()
                        }
                    } else {
                        Button(LocalizationKeys.homeCountryUpdate) {
                            viewModel.confirmHomeCountryAction()
                        }
                    }

                    Button(LocalizationKeys.generalCancel, role: .cancel) {}
                } message: {
                    Text(homeCountryConfirmationMessage)
                }
                .navigationDestination(for: Country.self) { country in
                    CountryDetailView(
                        country: country,
                        premiumEntitlement: premiumEntitlement,
                        travelPreferencesStore: travelPreferencesStore,
                        analyticsTracker: analyticsTracker
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSettingsPresented = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityIdentifier("countries.settings")
                        .accessibilityLabel(LocalizationKeys.settingsOpen)
                    }
                }
                .fullScreenCover(isPresented: $isSettingsPresented) {
                    SettingsView(
                        premiumEntitlement: premiumEntitlement,
                        travelPreferencesStore: travelPreferencesStore,
                        homeCountryViewModel: homeCountryViewModel,
                        analyticsTracker: analyticsTracker
                    )
                }
        }
    }

    private func openDeepLinkedCountryIfNeeded() {
        guard let countryCode = deepLinkedCountryCode,
              viewModel.openDeepLinkedCountry(code: countryCode) else {
            return
        }

        deepLinkedCountryCode = nil
    }

    private var homeCountryConfirmationTitle: LocalizedStringResource {
        viewModel.isPendingHomeCountryRemoval
            ? LocalizationKeys.homeCountryRemoveConfirmationTitle
            : LocalizationKeys.homeCountryUpdateConfirmationTitle
    }

    /// `String`, unlike `homeCountryConfirmationTitle` above: the other branch interpolates a
    /// country name through `.string(_:)`, and a resource can't carry a runtime argument with
    /// this catalog's opaque keys.
    private var homeCountryConfirmationMessage: String {
        guard !viewModel.isPendingHomeCountryRemoval,
              let pendingHomeCountry = viewModel.pendingHomeCountry else {
            return String(localized: LocalizationKeys.homeCountryRemoveConfirmationMessage)
        }

        return LocalizationKeys.homeCountryUpdateConfirmationMessage.string(
            pendingHomeCountry.localizedName(in: locale)
        )
    }
}

// MARK: - CountryResultsView

private struct CountryResultsView<ViewModel: CountriesListViewModelType>: View {
    let viewModel: ViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .md) {
                countryRows
            }
            .padding(.horizontal, .xxl)
            .padding(.bottom, .xxl)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .swipeActionsContainer()
        .accessibilityIdentifier("countries.list")
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LocalizationKeys.accessibilityCountriesList)
        .accessibilityHint(LocalizationKeys.accessibilityCountriesListDescription)
    }

    @ViewBuilder
    private var countryRows: some View {
        // `canSaveMoreCountries` is still read here, in the list's own body, rather than inside
        // `rowModel(for:)` — rows live in a `LazyVStack`, so a row already on screen is not
        // rebuilt when a *different* row's save fills the last free slot, and deriving the lock
        // per row left stale stars behind.
        let canSaveMoreCountries = viewModel.canSaveMoreCountries

        ForEach(viewModel.displayedCountries) { country in
            CountryBrowserRow(
                model: viewModel.rowModel(for: country),
                compatibility: viewModel.compatibilitySummaries[country.code],
                canSaveMoreCountries: canSaveMoreCountries,
                viewModel: viewModel
            )
        }

        if viewModel.displayedCountries.isEmpty {
            emptyState
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let searchQuery = viewModel.searchQuery

        if !searchQuery.isEmpty {
            ContentUnavailableView.search(text: searchQuery)
                .padding(.top, .special)
                .accessibilityLabel(LocalizationKeys.accessibilityEmptyState)
                .accessibilityValue(LocalizationKeys.accessibilitySearchResults.string(searchQuery))
                .accessibilityHint(LocalizationKeys.accessibilityEmptyStateDescription)
        } else if viewModel.selectedFilter != .all {
            ContentUnavailableView(
                LocalizationKeys.countriesFilterEmptyTitle,
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text(LocalizationKeys.countriesFilterEmptyDescription)
            )
            .padding(.top, .special)
        }
    }
}

// MARK: - CountriesListCompatibilityHeader

private struct CountriesListCompatibilityHeader<ViewModel: CountriesListViewModelType>: View {
    let viewModel: ViewModel
    let tip: CompatibilityFilterTip?

    var body: some View {
        @Bindable var viewModel = viewModel

        if !viewModel.filteredCountries.isEmpty, let homeCountry = viewModel.homeCountry {
            VStack(spacing: .xs) {
                HomeCountryBannerView(country: homeCountry, onClear: clearHomeCountry)
                    .padding(.horizontal, .xxl)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                // `viewModel.filterCounts` rather than a second copy of the same tallying loop
                // that used to live on this view — the view model already published it, and two
                // implementations of one rule is one too many.
                CompatibilityFilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    counts: viewModel.filterCounts,
                    tip: tip
                )
                .onChange(of: viewModel.selectedFilter) { oldValue, newValue in
                    guard oldValue != newValue else {
                        return
                    }

                    tip?.invalidate(reason: .actionPerformed)
                    viewModel.filterSelected()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            .padding(.vertical, .sm)
        }
    }

    private func clearHomeCountry() {
        guard let homeCountry = viewModel.homeCountry else {
            return
        }

        viewModel.handleHomeCountryAction(for: homeCountry)
    }
}

// MARK: - CompatibilityFilterBar

private struct CompatibilityFilterBar: View {
    @Binding var selectedFilter: CountryCompatibilityFilter
    let counts: [CountryCompatibilityFilter: Int]
    let tip: CompatibilityFilterTip?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: .sm) {
                HStack(spacing: .sm) {
                    ForEach(CountryCompatibilityFilter.allCases) { filter in
                        Button {
                            withMotionAwareAnimation(.snappy, reduceMotion: reduceMotion) {
                                selectedFilter = filter
                            }
                        } label: {
                            HStack(spacing: .xs) {
                                filter.icon.image
                                    .imageScale(.small)

                                Text(filter.title)

                                // `format:` rather than an interpolated literal: the literal was a
                                // `LocalizedStringKey`, so Xcode extracted "%@" into the catalog
                                // as a key. `.number` also localizes the digits.
                                Text(counts[filter, default: 0], format: .number)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .padding(.horizontal, .xs)
                                    .padding(.vertical, 2)
                                    .background(filter.isSelected(selectedFilter) ? .white.opacity(0.22) : .surfaceSecondary)
                                    .clipShape(Capsule())
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(filter.isSelected(selectedFilter) ? .white : filter.color)
                            .padding(.horizontal, .lg)
                            .padding(.vertical, .md)
                            .glassEffect(
                                filter.isSelected(selectedFilter)
                                    ? .regular.tint(filter.color.opacity(0.92)).interactive()
                                    : .regular.tint(filter.color.opacity(0.14)).interactive(),
                                in: .capsule
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, .xxl)
                .padding(.vertical, .xs)
            }
        }
        .popoverTip(tip, arrowEdge: .top)
        .appTipIconTint()
        .scrollClipDisabled()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - CompatibilityFilterTip

private struct CompatibilityFilterTip: Tip {
    var title: Text {
        Text(LocalizationKeys.compatibilityLegendTitle)
    }

    var message: Text? {
        Text(LocalizationKeys.countriesFilterTip)
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }
}

// MARK: - CountryCompatibilityFilter

enum CountryCompatibilityFilter: CaseIterable, Identifiable {
    case all
    case compatible
    case adapterNeeded
    case converterRequired

    var id: Self { self }

    /// `LocalizedStringResource`: a filter case is a long-lived value, and its label is only
    /// needed at the moment a pill renders.
    var title: LocalizedStringResource {
        switch self {
        case .all: LocalizationKeys.countriesFilterAll
        case .compatible: LocalizationKeys.compatibilityLegendCompatibleTitle
        case .adapterNeeded: LocalizationKeys.compatibilityLegendAdapterTitle
        case .converterRequired: LocalizationKeys.compatibilityLegendConverterTitle
        }
    }

    var icon: SFSymbols {
        switch self {
        case .all: .globeEuropeAfrica
        case .compatible: .checkmarkCircleFill
        case .adapterNeeded: .powerPlugFill
        case .converterRequired: .exclamationMarkTriangle
        }
    }

    var color: Color {
        switch self {
        case .all: .buttonInfoTint
        case .compatible: .statusReady
        case .adapterNeeded: .statusCheck
        case .converterRequired: .statusUnsafe
        }
    }

    func isSelected(_ selectedFilter: CountryCompatibilityFilter) -> Bool {
        self == selectedFilter
    }
}

extension CountriesListView where ViewModel == CountriesListViewModel {
    init(
        modelContext: ModelContext,
        homeCountryViewModel: any HomeCountryViewModelType,
        travelPreferencesStore: any TravelPreferencesStoring,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker,
        deepLinkedCountryCode: Binding<String?> = .constant(nil)
    ) {
        self.init(
            viewModel: CountriesListViewModel(
                modelContext: modelContext,
                homeCountryViewModel: homeCountryViewModel,
                travelPreferencesStore: travelPreferencesStore,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker
            ),
            deepLinkedCountryCode: deepLinkedCountryCode
        )
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    for code in ["AF", "IT", "GB", "FO", "GU"] {
        let country = Country(code: code, voltage: "230V", frequency: "50Hz", flagUnicode: "🏴‍☠️")
        container.mainContext.insert(country)
        country.plugs = [
            Plug(
                id: "A",
                images: [],
                specifications: .init(
                    pinDiameter: "1.5mm",
                    pinSpacing: "12.7mm",
                    ratedAmperage: "10A",
                    alsoKnownAs: "AS/NZS 3112"
                )
            ),
            Plug(
                id: "C",
                images: [],
                specifications: .init(
                    pinDiameter: "1.5mm",
                    pinSpacing: "12.7mm",
                    ratedAmperage: "10A",
                    alsoKnownAs: "CEE 7/16"
                )
            )
        ]
    }

    let descriptor = FetchDescriptor<Country>()
    let countries = (try? container.mainContext.fetch(descriptor)) ?? []
    let previewVM = PreviewCountriesListViewModel(countries: countries)

    return CountriesListView(viewModel: previewVM)
        .modelContainer(container)
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "IT", plugTypeIDs: ["A", "C"]))
}
#endif
