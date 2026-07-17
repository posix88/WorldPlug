import Analytics
import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - CountriesListView

struct CountriesListView<ViewModel: CountriesListViewModelType>: View {
    @State private var viewModel: ViewModel
    @State private var path = NavigationPath()
    @State private var searchQuery: String = ""
    @State private var selectedFilter: CountryCompatibilityFilter = .all
    @Binding private var deepLinkedCountryCode: String?
    @Environment(\.homeCountryViewModel) private var homeViewModel
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.locale) private var locale
    private let compatibilityFilterTip = CompatibilityFilterTip()

    init(
        viewModel: ViewModel,
        deepLinkedCountryCode: Binding<String?> = .constant(nil)
    ) {
        _viewModel = State(initialValue: viewModel)
        _deepLinkedCountryCode = deepLinkedCountryCode
    }

    var body: some View {
        let compatibilitySummaries = self.compatibilitySummaries
        let countries = displayedCountries(using: compatibilitySummaries)

        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: .md) {
                    ForEach(countries) { country in
                        CountryBrowserRow(
                            country: country,
                            compatibility: compatibilitySummaries[country.code]
                        )
                    }

                    if countries.isEmpty {
                        emptyState
                    }
                }
                .navigationDestination(for: Country.self) { country in
                    CountryDetailView(country: country)
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
                .padding(.horizontal, .xxl)
                .padding(.bottom, .xxl)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(LocalizationKeys.accessibilityCountriesList.localized(from: .accessibility))
                .accessibilityHint(LocalizationKeys.accessibilityCountriesListDescription.localized(from: .accessibility))
            }
            .background { AppMeshBackground() }
            .scrollContentBackground(.hidden)
            .safeAreaBar(edge: .top, spacing: 0) {
                compatibilityHeader(using: compatibilitySummaries)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .searchable(
                text: $searchQuery,
                prompt: Text(LocalizationKeys.searchCountriesPlaceholder.localized)
            )
            .onChange(of: searchQuery) { oldValue, newValue in
                guard oldValue != newValue else {
                    return
                }

                viewModel.search(query: newValue, locale: locale)
            }
            .onChange(of: locale.identifier) { _, _ in
                viewModel.search(query: searchQuery, locale: locale)
            }
            .onAppear {
                analyticsTracker.screen(.countries)
                viewModel.search(query: searchQuery, locale: locale)
                openDeepLinkedCountryIfNeeded()
            }
            .onChange(of: deepLinkedCountryCode) { _, _ in
                openDeepLinkedCountryIfNeeded()
            }
            .onChange(of: homeViewModel.homeCountryCode) { _, newValue in
                if newValue.isEmpty {
                    selectedFilter = .all
                }
            }
        }
    }

    private func openDeepLinkedCountryIfNeeded() {
        guard let countryCode = deepLinkedCountryCode,
              let country = viewModel.filteredCountries.first(where: { $0.code == countryCode }) else {
            return
        }

        selectedFilter = .all
        searchQuery = ""
        path = NavigationPath()
        path.append(country)
        deepLinkedCountryCode = nil
    }

    private var compatibilitySummaries: [String: CountryCompatibilitySummary] {
        Dictionary(
            uniqueKeysWithValues: viewModel.filteredCountries.compactMap { country in
                compatibilitySummary(for: country).map { (country.code, $0) }
            }
        )
    }

    private func displayedCountries(
        using compatibilitySummaries: [String: CountryCompatibilitySummary]
    ) -> [Country] {
        guard selectedFilter != .all, !homeViewModel.homeCountryCode.isEmpty else {
            return viewModel.filteredCountries
        }

        return viewModel.filteredCountries.filter { country in
            compatibilitySummaries[country.code]?.filter == selectedFilter
        }
    }

    private func filterCounts(
        using compatibilitySummaries: [String: CountryCompatibilitySummary]
    ) -> [CountryCompatibilityFilter: Int] {
        var counts = Dictionary(uniqueKeysWithValues: CountryCompatibilityFilter.allCases.map { ($0, 0) })
        counts[.all] = viewModel.filteredCountries.count

        for filter in compatibilitySummaries.values.map(\.filter) {
            counts[filter, default: 0] += 1
        }

        return counts
    }

    @ViewBuilder
    private func compatibilityHeader(
        using compatibilitySummaries: [String: CountryCompatibilitySummary]
    ) -> some View {
        if !viewModel.filteredCountries.isEmpty, let homeCountry = homeViewModel.homeCountry {
            VStack(spacing: .xs) {
                HomeCountryBannerView(country: homeCountry) {
                    homeViewModel.clearHome()
                }
                .padding(.horizontal, .xxl)
                .transition(.opacity.combined(with: .move(edge: .top)))

                CompatibilityFilterBar(
                    selectedFilter: $selectedFilter,
                    counts: filterCounts(using: compatibilitySummaries),
                    tip: compatibilityFilterTip
                )
                .onChange(of: selectedFilter) { oldValue, newValue in
                    guard oldValue != newValue else {
                        return
                    }

                    compatibilityFilterTip.invalidate(reason: .actionPerformed)
                    analyticsTracker.track(.compatibilityFilterSelected)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            .padding(.vertical, .sm)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.filteredCountries.isEmpty && !searchQuery.isEmpty {
            ContentUnavailableView.search(text: searchQuery)
                .padding(.top, .special)
                .accessibilityLabel(LocalizationKeys.accessibilityEmptyState.localized(from: .accessibility))
                .accessibilityValue(LocalizationKeys.accessibilitySearchResults.localized(
                    from: .accessibility,
                    searchQuery
                ))
                .accessibilityHint(LocalizationKeys.accessibilityEmptyStateDescription
                    .localized(from: .accessibility)
                )
        } else if selectedFilter != .all {
            ContentUnavailableView(
                LocalizationKeys.countriesFilterEmptyTitle.localized,
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text(LocalizationKeys.countriesFilterEmptyDescription.localized)
            )
            .padding(.top, .special)
        }
    }

    private func compatibilitySummary(for country: Country) -> CountryCompatibilitySummary? {
        guard !homeViewModel.homeCountryCode.isEmpty else {
            return nil
        }
        guard country.code != homeViewModel.homeCountryCode else {
            return .compatible
        }

        let plugCompatibilities = country.sortedPlugs.map {
            homeViewModel.plugCompatibility(for: $0, in: country)
        }

        if plugCompatibilities.contains(.converterRequired) {
            return .converterRequired
        }

        if plugCompatibilities.contains(.adapterNeeded) {
            return .adapterNeeded
        }

        return .compatible
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
                        .background {
                            Capsule()
                                .fill(.thinMaterial)
                                .overlay(
                                    Capsule()
                                        .fill(filter.isSelected(selectedFilter) ? filter.color.opacity(0.92) : filter.color
                                            .opacity(0.14)
                                        )
                                )
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    filter.color.opacity(filter.isSelected(selectedFilter) ? 0.28 : 0.22),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: filter.color.opacity(filter.isSelected(selectedFilter) ? 0.28 : 0.12),
                            radius: filter.isSelected(selectedFilter) ? 10 : 6,
                            x: 0,
                            y: 2
                        )
                        .shadow(
                            color: filter.color.opacity(filter.isSelected(selectedFilter) ? 0.14 : 0.06),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .xxl)
            .padding(.vertical, .xs)
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
        case .compatible: .green
        case .adapterNeeded: .orange
        case .converterRequired: .red
        }
    }

    func isSelected(_ selectedFilter: CountryCompatibilityFilter) -> Bool {
        self == selectedFilter
    }
}

// MARK: - CountryCompatibilitySummary

enum CountryCompatibilitySummary {
    case compatible
    case adapterNeeded
    case converterRequired

    var filter: CountryCompatibilityFilter {
        switch self {
        case .compatible: .compatible
        case .adapterNeeded: .adapterNeeded
        case .converterRequired: .converterRequired
        }
    }

    var title: String { filter.title }
    var icon: SFSymbols { filter.icon }
    var color: Color { filter.color }
}

extension CountriesListView where ViewModel == CountriesListViewModel {
    init(
        modelContext: ModelContext,
        deepLinkedCountryCode: Binding<String?> = .constant(nil)
    ) {
        self.init(
            viewModel: CountriesListViewModel(modelContext: modelContext),
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
