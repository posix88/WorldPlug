import SwiftUI
import ComposableArchitecture

@main
struct WorldPlugApp: App {
    static let store = Store(initialState: CountriesListFeature.State()) {
        CountriesListFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            CountriesListView(store: WorldPlugApp.store)
        }
    }
}
