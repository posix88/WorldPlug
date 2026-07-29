import Analytics
import Repository
import SwiftData
import SwiftUI

// MARK: - VoltlyApp

@main
struct VoltlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var travelPreferencesStore: ICloudTravelPreferencesStore
    @State private var homeCountryViewModel: HomeCountryViewModel
    @State private var premiumEntitlement: StoreKitPremiumEntitlement
    @State private var coordinator: AppCoordinator
    private let analyticsTracker: any AnalyticsTracker
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let analyticsTracker = FirebaseAnalyticsTracker()
        self.analyticsTracker = analyticsTracker
        let travelPreferencesStore = ICloudTravelPreferencesStore(analyticsTracker: analyticsTracker)
        _travelPreferencesStore = State(initialValue: travelPreferencesStore)
        let homeCountryViewModel = HomeCountryViewModel(
            travelPreferencesStore: travelPreferencesStore,
            analyticsTracker: analyticsTracker,
            modelContext: Repository.sharedModelContainer.mainContext
        )
        _homeCountryViewModel = State(initialValue: homeCountryViewModel)
        let premiumEntitlement = StoreKitPremiumEntitlement()
        _premiumEntitlement = State(initialValue: premiumEntitlement)
        _coordinator = State(
            initialValue: AppCoordinator(
                homeCountryViewModel: homeCountryViewModel,
                premiumEntitlement: premiumEntitlement,
                appGroupDefaults: UserDefaults(suiteName: AppGroup.identifier) ?? .standard,
                standardDefaults: .standard
            )
        )
        VoltlyAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        @Bindable var coordinator = coordinator

        WindowGroup {
            ZStack {
                RootTabView(
                    modelContext: Repository.sharedModelContainer.mainContext,
                    deepLinkedCountryCode: $coordinator.deepLinkedCountryCode,
                    selectedTab: $coordinator.selectedTab
                )
                .environment(\.homeCountryViewModel, homeCountryViewModel)
                .environment(\.travelPreferencesStore, travelPreferencesStore)
                .environment(\.premiumEntitlement, premiumEntitlement)
                .environment(\.analyticsTracker, analyticsTracker)
                .sheet(item: $coordinator.premiumPaywallSource) { source in
                    PremiumPaywallView(source: source)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        coordinator.sceneBecameActive()
                    }
                }
                .task {
                    await coordinator.start()
                }
                .onChange(of: premiumEntitlement.isPremium) { _, _ in
                    coordinator.premiumStatusChanged()
                }
                .onOpenURL(perform: coordinator.open)
                .fullScreenCover(isPresented: $coordinator.isOnboardingPresented) {
                    OnboardingView(
                        modelContext: Repository.sharedModelContainer.mainContext,
                        homeCountryViewModel: homeCountryViewModel,
                        analyticsTracker: analyticsTracker
                    ) {
                        analyticsTracker.track(.onboardingCompleted)
                        coordinator.onboardingCompleted()
                    }
                }

                if coordinator.isLaunchExperiencePresented {
                    LaunchExperienceView(dismiss: coordinator.launchExperienceCompleted)
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(Repository.sharedModelContainer)
    }

}
