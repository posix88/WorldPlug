import ComposableArchitecture
import Foundation
import Repository
import SwiftData

@Reducer
struct CountryDetailFeature {
    @ObservableState
    struct State {
        var country: Country
    }

    enum Action {
        case openDetail(plug: Plug)
    }
}
