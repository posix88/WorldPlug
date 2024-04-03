//
//  CountriesListFeature.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 02/04/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct CountriesListFeature {
    @ObservableState
    struct State {
        var countries: [Country] = []
    }

    enum Action {
        case loadView
        case viewLoaded(countries: [Country])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadView:
                return .run { send in
                    guard let url = WorldPlugResources.bundle.url(forResource: "countries", withExtension: "json") else {
                        await send(.viewLoaded(countries: []))
                        return
                    }
                    let data = try Data(contentsOf: url)
                    let countries = try JSONDecoder().decode([Country].self, from: data)
                    await send(.viewLoaded(countries: countries))
                }
            case .viewLoaded(let countries):
                state.countries = countries
                return .none
            }
        }
    }
}
