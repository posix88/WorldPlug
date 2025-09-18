import SwiftUI
import ComposableArchitecture
import Repository
import SwiftData

@main
struct WorldPlugApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    static let store = Store(initialState: CountriesListFeature.State()) {
        CountriesListFeature()
    }

    var body: some Scene {
        WindowGroup {
            CountriesListView(store: WorldPlugApp.store)
        }
        .modelContainer(Repository.sharedModelContainer)
    }
}
