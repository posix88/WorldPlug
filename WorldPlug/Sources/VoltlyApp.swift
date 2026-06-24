import Repository
import SwiftData
import SwiftUI

@main
struct VoltlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var homeCountryViewModel = HomeCountryViewModel(
        modelContext: Repository.sharedModelContainer.mainContext
    )

    var body: some Scene {
        WindowGroup {
            CountriesListView(modelContext: Repository.sharedModelContainer.mainContext)
                .environment(homeCountryViewModel)
        }
        .modelContainer(Repository.sharedModelContainer)
    }
}
