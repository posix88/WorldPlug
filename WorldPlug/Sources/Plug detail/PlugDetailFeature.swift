import ComposableArchitecture
import CoreGraphics
import Repository

@Reducer
struct PlugDetailFeature {
    @ObservableState
    struct State {
        var plug: Plug
        var viewSize: CGSize = .zero
    }

    enum Action {
        case sizeUpdated(CGSize)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sizeUpdated(let newSize):
                state.viewSize = newSize
                return .none
            }
        }
    }
}
