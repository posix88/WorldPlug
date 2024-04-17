import ComposableArchitecture
import Repository_iOS

@Reducer
struct PlugDetailFeature {
    @ObservableState
    struct State {
        var plug: Plug
        var currentTab: Int = 0
    }

    enum Action {
        case tabUpdated(Int)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tabUpdated(let newTab):
                state.currentTab = newTab
                return .none
            }
        }
    }
}
