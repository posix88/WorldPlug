import ComposableArchitecture
import SwiftData
import Foundation
import Repository

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
