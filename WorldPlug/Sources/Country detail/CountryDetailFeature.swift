import ComposableArchitecture
import SwiftData
import Foundation
import Repository_iOS

@Reducer
struct CountryDetailFeature {
    @ObservableState
    struct State {
        var country: Country
    }
}
