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
    @State private var navigationModel: AppNavigationModel
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
        let navigationModel = AppNavigationModel.shared
        _navigationModel = State(initialValue: navigationModel)
        let coordinator = AppCoordinator(
            homeCountryViewModel: homeCountryViewModel,
            premiumEntitlement: premiumEntitlement,
            navigationModel: navigationModel,
            appGroupDefaults: UserDefaults(suiteName: AppGroup.identifier) ?? .standard,
            standardDefaults: .standard
        )
        _coordinator = State(initialValue: coordinator)
        VoltlyAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        @Bindable var coordinator = coordinator
        @Bindable var navigationModel = navigationModel

        WindowGroup {
            ZStack {
                switch coordinator.phase {
                case .launchExperience:
                    LaunchExperienceView(
                        isReady: coordinator.hasRefreshedEntitlements,
                        dismiss: coordinator.launchExperienceCompleted
                    )
                    .transition(.opacity)

                case .onboarding:
                    OnboardingView(
                        modelContext: Repository.sharedModelContainer.mainContext,
                        homeCountryViewModel: homeCountryViewModel,
                        analyticsTracker: analyticsTracker
                    ) {
                        analyticsTracker.track(.onboardingCompleted)
                        coordinator.onboardingCompleted()
                    }
                    .transition(.opacity)

                case .main:
                    RootTabView(
                        modelContext: Repository.sharedModelContainer.mainContext,
                        deepLinkedCountryCode: $navigationModel.deepLinkedCountryCode,
                        selectedTab: $navigationModel.selectedTab
                    )
                    .transition(.opacity)
                }
            }
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
        }
        .modelContainer(Repository.sharedModelContainer)
    }
}
