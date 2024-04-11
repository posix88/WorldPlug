import ComposableArchitecture
import SwiftData
import Foundation
import Repository_iOS

@Reducer
struct CountryDetailFeature {
    @ObservableState
    struct State {
        var country: Country
        var plugs: [Plug] = []
    }

    enum Action {
        case viewLoaded
        case searchResult(plugs: [Plug])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewLoaded:
                return .none
//                    .run { [types = state.country.plugTypes] send in
//                    await send(.searchResult(plugs: Repository.allPlugsByIDs(types)))
//                }
                
            case .searchResult(let plugs):
                state.plugs = plugs
                return .none
            }
        }
    }
}
