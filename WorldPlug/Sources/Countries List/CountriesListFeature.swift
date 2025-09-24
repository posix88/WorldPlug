import Foundation
import ComposableArchitecture
import Repository

@Reducer
struct CountriesListFeature {
    @ObservableState
    struct State {
        var countries: [Country] = []
        var filteredCountries: [Country] = []
        var searchQuery = ""
        var selectedPlug: Plug?
        var path = StackState<Path.State>()
    }

    enum Action {
        case viewLoaded(countries: [Country])
        case searchQueryChanged(String)
        case openPlugDetail(Plug?)
        case searchResult(countries: [Country])
        case openDetail(country: Country)
        case path(StackAction<Path.State, Path.Action>)
    }

    @Reducer
    enum Path {
        case countryDetail(CountryDetailFeature)
        case plugDetail(PlugDetailFeature)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewLoaded(let countries):
                state.countries = countries
                state.filteredCountries = countries
                return .none

            case .searchQueryChanged(let query):
                state.searchQuery = query
                guard !query.isEmpty else {
                    state.filteredCountries = state.countries
                    return .none
                }
                // Perform filtering synchronously to avoid Sendable issues
                state.filteredCountries = state.countries.lazy.filter { $0.name.lowercased().contains(query.lowercased()) }
                return .none

            case .searchResult(let countries):
                state.filteredCountries = countries
                return .none

            case .openPlugDetail(let plug):
                guard let plug else { return .none }
                state.path.append(.plugDetail(PlugDetailFeature.State(plug: plug)))
                return .none

            case .openDetail(let country):
                if country.plugs.count > 1 {
                    state.path.append(.countryDetail(CountryDetailFeature.State(country: country)))
                } else if let plug = country.plugs.first {
                    state.path.append(.plugDetail(PlugDetailFeature.State(plug: plug)))
                }
                return .none

            case .path(.element(id: _, action: .countryDetail(.openDetail(plug: let plug)))):
                state.path.append(.plugDetail(PlugDetailFeature.State(plug: plug)))
                return .none

            case .path:
                return .none

            }
        }
        .forEach(\.path, action: \.path)
    }
}
