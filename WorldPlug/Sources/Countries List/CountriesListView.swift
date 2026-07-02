import Repository
import SwiftData
import SwiftUI

// MARK: - CountriesListView

struct CountriesListView<ViewModel: CountriesListViewModelType>: View {
    @State private var viewModel: ViewModel
    @State private var path = NavigationPath()
    @State private var searchQuery: String = ""
    @State private var selectedFilter: CountryCompatibilityFilter = .all
    @Environment(\.homeCountryViewModel) private var homeViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: .md) {
                    if !viewModel.filteredCountries.isEmpty {
                        CountriesHeaderView(countryCount: displayedCountries.count)

                        if let homeCountry = homeViewModel.homeCountry {
                            HomeCountryBannerView(country: homeCountry) {
                                homeViewModel.clearHome()
                            }
                            .padding(.bottom, .xs)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                            CompatibilityFilterBar(
                                selectedFilter: $selectedFilter,
                                counts: filterCounts
                            )
                            .padding(.horizontal, -.xxl)
                            .padding(.bottom, .xs)
                            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                        }
                    }

                    ForEach(displayedCountries) { country in
                        CountryBrowserRow(
                            country: country,
                            compatibility: compatibilitySummary(for: country)
                        )
                    }

                    if displayedCountries.isEmpty {
                        emptyState
                    }
                }
                .navigationDestination(for: Plug.self) { plug in
                    PlugDetailView(plug: plug)
                }
                .padding(.horizontal, .xxl)
                .padding(.bottom, .xxl)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(LocalizationKeys.accessibilityCountriesList.localized(from: .accessibility))
                .accessibilityHint(LocalizationKeys.accessibilityCountriesListDescription.localized(from: .accessibility))
            }
            .background { AppMeshBackground() }
            .scrollContentBackground(.hidden)
            .searchable(
                text: $searchQuery,
                prompt: Text(LocalizationKeys.searchCountriesPlaceholder.localized)
            )
            .onChange(of: searchQuery) { oldValue, newValue in
                guard oldValue != newValue else {
                    return
                }

                viewModel.search(query: newValue)
            }
            .onChange(of: homeViewModel.homeCountryCode) { _, newValue in
                if newValue.isEmpty {
                    selectedFilter = .all
                }
            }
            .navigationTitle(LocalizationKeys.appTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityLabel(LocalizationKeys.accessibilityNavigationTitle.localized(from: .accessibility))
        }
    }

    private var displayedCountries: [Country] {
        guard selectedFilter != .all, !homeViewModel.homeCountryCode.isEmpty else {
            return viewModel.filteredCountries
        }

        return viewModel.filteredCountries.filter { country in
            compatibilitySummary(for: country)?.filter == selectedFilter
        }
    }

    private var filterCounts: [CountryCompatibilityFilter: Int] {
        var counts = Dictionary(uniqueKeysWithValues: CountryCompatibilityFilter.allCases.map { ($0, 0) })
        counts[.all] = viewModel.filteredCountries.count

        for country in viewModel.filteredCountries {
            guard let filter = compatibilitySummary(for: country)?.filter else {
                continue
            }

            counts[filter, default: 0] += 1
        }

        return counts
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

// MARK: - CountriesHeaderView

private struct CountriesHeaderView: View {
    let countryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            Text(LocalizationKeys.countriesTitle.localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.textRegular)

            Text(LocalizationKeys.countriesAvailable.localized(countryCount))
                .font(.subheadline)
                .foregroundStyle(.textLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, .md)
        .padding(.bottom, .xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizationKeys.accessibilityCountriesHeader.localized(from: .accessibility))
        .accessibilityValue(LocalizationKeys.accessibilityCountryAvailableCount.localized(
            from: .accessibility,
            countryCount
        ))
    }
}

// MARK: - CompatibilityFilterBar

private struct CompatibilityFilterBar: View {
    @Binding var selectedFilter: CountryCompatibilityFilter
    let counts: [CountryCompatibilityFilter: Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .sm) {
                ForEach(CountryCompatibilityFilter.allCases) { filter in
                    Button {
                        withAnimation(.snappy) {
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
                                .strokeBorder(filter.color.opacity(filter.isSelected(selectedFilter) ? 0.28 : 0.22), lineWidth: 1)
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
        .scrollClipDisabled()
        .accessibilityElement(children: .contain)
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
    init(modelContext: ModelContext) {
        self.init(viewModel: CountriesListViewModel(modelContext: modelContext))
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
                name: "Type A",
                shortInfo: "short info",
                info: "info",
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
                name: "Type C",
                shortInfo: "short info",
                info: "info",
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

    let descriptor = FetchDescriptor<Country>(sortBy: [SortDescriptor(\.name)])
    let countries = (try? container.mainContext.fetch(descriptor)) ?? []
    let previewVM = PreviewCountriesListViewModel(countries: countries)

    return CountriesListView(viewModel: previewVM)
        .modelContainer(container)
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel(homeCountryCode: "IT", plugTypeIDs: ["A", "C"]))
}
#endif
