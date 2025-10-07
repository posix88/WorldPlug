import Repository
import SwiftData
import SwiftUI

@main
struct WorldPlugApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            CountriesListView(modelContext: Repository.sharedModelContainer.mainContext)
        }
        .modelContainer(Repository.sharedModelContainer)
    }
}
