import Foundation
import ComposableArchitecture
import Repository_iOS

@Reducer
struct CountriesListFeature {
    @ObservableState
    struct State {
        var countries: [Country] = []
        var filteredCountries: [Country] = []
        var searchQuery = ""
        var path = StackState<Path.State>()
    }

    enum Action {
        case viewLoaded(countries: [Country])
        case searchQueryChanged(String)
        case searchResult(countries: [Country])
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
                guard !query.isEmpty else {
                    state.filteredCountries = state.countries
                    return .none
                }
                return .run { [countries = state.countries] send in
                    let filter = countries.filter { $0.name.lowercased().contains(query.lowercased()) }
                    await send(.searchResult(countries: filter ))
                }

            case .searchResult(let countries):
                state.filteredCountries = countries
                return .none

            case .path:
                return .none

            }
        }
        .forEach(\.path, action: \.path)
    }
}
