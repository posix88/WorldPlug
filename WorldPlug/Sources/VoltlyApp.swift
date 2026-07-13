import Repository
import SwiftData
import SwiftUI

@main
struct VoltlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var homeCountryViewModel = HomeCountryViewModel(
        modelContext: Repository.sharedModelContainer.mainContext
    )
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            CountriesListView(modelContext: Repository.sharedModelContainer.mainContext)
                .environment(\.homeCountryViewModel, homeCountryViewModel)
                .fullScreenCover(isPresented: onboardingPresentationBinding) {
                    OnboardingView(
                        modelContext: Repository.sharedModelContainer.mainContext
                    ) {
                        hasSeenOnboarding = true
                    }
                    .environment(\.homeCountryViewModel, homeCountryViewModel)
                }
        }
        .modelContainer(Repository.sharedModelContainer)
    }

    private var onboardingPresentationBinding: Binding<Bool> {
        Binding(
            get: { !hasSeenOnboarding },
            set: { isPresented in
                if !isPresented {
                    hasSeenOnboarding = true
                }
            }
        )
    }
}
