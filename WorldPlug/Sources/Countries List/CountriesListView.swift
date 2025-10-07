import Repository
import SwiftData
import SwiftUI

// MARK: - CountriesListView

struct CountriesListView: View {
    @State private var viewModel: CountriesListViewModel
    @State private var path = NavigationPath()
    @State private var searchQuery: String = ""

    init(modelContext: ModelContext) {
        let viewModel = CountriesListViewModel(modelContext: modelContext)
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
                        .padding(.bottom, .lg)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(LocalizationKeys.accessibilityCountriesHeader.localized(from: .accessibility))
                        .accessibilityValue(LocalizationKeys.accessibilityCountryAvailableCount.localized(
                            from: .accessibility,
                            viewModel.filteredCountries.count
                        ))
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
            .background(.backgroundSurface)
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

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)

    for i in ["AF", "IT", "GB", "FO", "GU"] {
        let country = Country(code: "\(i)", voltage: "230V", frequency: "50Hz", flagUnicode: "🏴‍☠️")
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
                id: "B",
                name: "Type B",
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
                name: "Type B",
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
                id: "D",
                name: "Type B",
                shortInfo: "short info",
                info: "info",
                images: [],
                specifications: .init(
                    pinDiameter: "1.5mm",
                    pinSpacing: "12.7mm",
                    ratedAmperage: "10A",
                    alsoKnownAs: "AS/NZS 3112"
                )
            )
        ]
    }

    return CountriesListView(modelContext: container.mainContext)
        .modelContainer(container)
}
#endif
