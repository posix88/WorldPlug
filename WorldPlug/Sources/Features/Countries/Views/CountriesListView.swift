import Analytics
import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - CountriesListView

struct CountriesListView<ViewModel: CountriesListViewModelType>: View {
    @State private var viewModel: ViewModel
    @Binding private var deepLinkedCountryCode: String?
    @Environment(\.locale) private var locale
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.analyticsTracker) private var analyticsTracker
    private let compatibilityFilterTip = CompatibilityFilterTip()

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
            CountryResultsView(
                countries: viewModel.displayedCountries,
                compatibilitySummaries: viewModel.compatibilitySummaries,
                searchQuery: viewModel.searchQuery,
                selectedFilter: viewModel.selectedFilter,
                rowModel: viewModel.rowModel,
                onToggleHomeCountry: viewModel.toggleHomeCountry,
                onToggleSavedCountry: viewModel.toggleSavedCountry
            )
            .background { AppMeshBackground() }
            .scrollContentBackground(.hidden)
            .safeAreaBar(edge: .top, spacing: 0) {
                CountriesListCompatibilityHeader(
                    homeCountry: viewModel.homeCountry,
                    countriesCount: viewModel.filteredCountries.count,
                    summaries: viewModel.compatibilitySummaries,
                    selectedFilter: $viewModel.selectedFilter,
                    tip: compatibilityFilterTip,
                    onClearHomeCountry: viewModel.clearHomeCountry,
                    onFilterSelected: viewModel.filterSelected
                )
            }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(LocalizationKeys.searchCountriesPlaceholder.localized)
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
                viewModel.screenAppeared(locale: locale)
                openDeepLinkedCountryIfNeeded()
            }
            .onChange(of: deepLinkedCountryCode) { _, _ in
                openDeepLinkedCountryIfNeeded()
            }
            .onChange(of: viewModel.homeCountry?.code) { _, _ in
                viewModel.homeCountryChanged()
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
        }
    }

    private func openDeepLinkedCountryIfNeeded() {
        guard let countryCode = deepLinkedCountryCode,
              viewModel.openDeepLinkedCountry(code: countryCode) else {
            return
        }

        deepLinkedCountryCode = nil
    }
}

// MARK: - CountryResultsView

private struct CountryResultsView: View {
    let countries: [Country]
    let compatibilitySummaries: [String: CountryCompatibilitySummary]
    let searchQuery: String
    let selectedFilter: CountryCompatibilityFilter
    let rowModel: (Country) -> CountryBrowserRowModel
    let onToggleHomeCountry: (String) -> Void
    let onToggleSavedCountry: (String) -> Bool

    var body: some View {
        Group {
            if #available(iOS 27.0, *) {
                ScrollView {
                    LazyVStack(spacing: .md) {
                        countryRows
                    }
                    .padding(.horizontal, .xxl)
                    .padding(.bottom, .xxl)
                }
                .swipeActionsContainer()
            } else {
                List {
                    countryRows
                        .listRowInsets(.init(top: 0, leading: .xxl, bottom: .md, trailing: .xxl))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .navigationLinkIndicatorVisibility(.hidden)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LocalizationKeys.accessibilityCountriesList.localized(from: .accessibility))
        .accessibilityHint(LocalizationKeys.accessibilityCountriesListDescription.localized(from: .accessibility))
    }

    @ViewBuilder
    private var countryRows: some View {
        ForEach(countries) { country in
            CountryBrowserRow(
                model: rowModel(country),
                compatibility: compatibilitySummaries[country.code],
                onToggleHomeCountry: onToggleHomeCountry,
                onToggleSavedCountry: onToggleSavedCountry
            )
        }

        if countries.isEmpty {
            emptyState
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchQuery.isEmpty {
            ContentUnavailableView.search(text: searchQuery)
                .padding(.top, .special)
                .accessibilityLabel(LocalizationKeys.accessibilityEmptyState.localized(from: .accessibility))
                .accessibilityValue(LocalizationKeys.accessibilitySearchResults.localized(from: .accessibility, searchQuery))
                .accessibilityHint(LocalizationKeys.accessibilityEmptyStateDescription.localized(from: .accessibility))
        } else if selectedFilter != .all {
            ContentUnavailableView(
                LocalizationKeys.countriesFilterEmptyTitle.localized,
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text(LocalizationKeys.countriesFilterEmptyDescription.localized)
            )
            .padding(.top, .special)
        }
    }
}

// MARK: - CountriesListCompatibilityHeader

private struct CountriesListCompatibilityHeader: View {
    let homeCountry: Country?
    let countriesCount: Int
    let summaries: [String: CountryCompatibilitySummary]
    @Binding var selectedFilter: CountryCompatibilityFilter
    let tip: CompatibilityFilterTip
    let onClearHomeCountry: () -> Void
    let onFilterSelected: () -> Void

    var body: some View {
        if countriesCount > 0, let homeCountry {
            VStack(spacing: .xs) {
                HomeCountryBannerView(country: homeCountry, onClear: onClearHomeCountry)
                    .padding(.horizontal, .xxl)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                CompatibilityFilterBar(selectedFilter: $selectedFilter, counts: filterCounts, tip: tip)
                    .onChange(of: selectedFilter) { oldValue, newValue in
                        guard oldValue != newValue else {
                            return
                        }

                        tip.invalidate(reason: .actionPerformed)
                        onFilterSelected()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            .padding(.vertical, .sm)
        }
    }

    private var filterCounts: [CountryCompatibilityFilter: Int] {
        var counts = Dictionary(uniqueKeysWithValues: CountryCompatibilityFilter.allCases.map { ($0, 0) })
        counts[.all] = countriesCount
        for filter in summaries.values.map(\.filter) {
            counts[filter, default: 0] += 1
        }
        return counts
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

                                Text("\(counts[filter, default: 0])")
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
        Text(LocalizationKeys.compatibilityLegendTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.countriesFilterTip.localized)
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

    var title: String {
        switch self {
        case .all: LocalizationKeys.countriesFilterAll.localized
        case .compatible: LocalizationKeys.compatibilityLegendCompatibleTitle.localized
        case .adapterNeeded: LocalizationKeys.compatibilityLegendAdapterTitle.localized
        case .converterRequired: LocalizationKeys.compatibilityLegendConverterTitle.localized
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
