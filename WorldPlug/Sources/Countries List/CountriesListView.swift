import Repository
import SwiftData
import SwiftUI

// MARK: - CountriesListView

struct CountriesListView<ViewModel: CountriesListViewModelType>: View {
    @State private var viewModel: ViewModel
    @State private var path = NavigationPath()
    @State private var searchQuery: String = ""
    @Environment(\.homeCountryViewModel) private var homeViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: .lg) {
                    // Enhanced header section when there are countries
                    if !viewModel.filteredCountries.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: .xs) {
                                Text(LocalizationKeys.countriesTitle.localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.textRegular)

                                Text(LocalizationKeys.countriesAvailable.localized(viewModel.filteredCountries.count))
                                    .font(.subheadline)
                                    .foregroundStyle(.textLight)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, .md)
                        .padding(.bottom, homeViewModel.homeCountry != nil ? .xs : .lg)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(LocalizationKeys.accessibilityCountriesHeader.localized(from: .accessibility))
                        .accessibilityValue(LocalizationKeys.accessibilityCountryAvailableCount.localized(
                            from: .accessibility,
                            viewModel.filteredCountries.count
                        ))

                        // Home country context banner
                        if let homeCountry = homeViewModel.homeCountry {
                            HomeCountryBannerView(country: homeCountry) {
                                homeViewModel.clearHome()
                            }
                            .padding(.bottom, .xs)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Countries list
                    ForEach(viewModel.filteredCountries) { country in
                        CountryCard(country: country)
                    }

                    // Empty state
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
            .navigationTitle(LocalizationKeys.appTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityLabel(LocalizationKeys.accessibilityNavigationTitle.localized(from: .accessibility))
        }
    }
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
