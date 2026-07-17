import Analytics
import Repository
import SwiftData
import SwiftUI
import WidgetKit

@main
struct VoltlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var travelPreferencesStore: ICloudTravelPreferencesStore
    @State private var homeCountryViewModel: HomeCountryViewModel
    @State private var premiumEntitlement: StoreKitPremiumEntitlement
    private let analyticsTracker: any AnalyticsTracker
    @State private var deepLinkedCountryCode: String?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let analyticsTracker = FirebaseAnalyticsTracker()
        self.analyticsTracker = analyticsTracker
        let travelPreferencesStore = ICloudTravelPreferencesStore(analyticsTracker: analyticsTracker)
        _travelPreferencesStore = State(initialValue: travelPreferencesStore)
        _homeCountryViewModel = State(
            initialValue: HomeCountryViewModel(
                travelPreferencesStore: travelPreferencesStore,
                analyticsTracker: analyticsTracker,
                modelContext: Repository.sharedModelContainer.mainContext
            )
        )
        _premiumEntitlement = State(initialValue: StoreKitPremiumEntitlement())
        VoltlyAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                modelContext: Repository.sharedModelContainer.mainContext,
                deepLinkedCountryCode: $deepLinkedCountryCode
            )
                .environment(\.homeCountryViewModel, homeCountryViewModel)
                .environment(\.travelPreferencesStore, travelPreferencesStore)
                .environment(\.premiumEntitlement, premiumEntitlement)
                .environment(\.analyticsTracker, analyticsTracker)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        homeCountryViewModel.refreshHomeCountry()
                        openPendingCountryIfNeeded()
                    }
                }
                .onAppear(perform: syncPremiumWidgetAccess)
                .onAppear(perform: openPendingCountryIfNeeded)
                .task {
                    await premiumEntitlement.refreshEntitlements()
                }
                .onChange(of: premiumEntitlement.isPremium) { _, _ in
                    syncPremiumWidgetAccess()
                }
                .onOpenURL { url in
                    guard url.scheme == "voltly",
                          url.host == "country",
                          let countryCode = url.pathComponents.dropFirst().first else {
                        return
                    }
                    deepLinkedCountryCode = countryCode.uppercased()
                }
                .fullScreenCover(isPresented: onboardingPresentationBinding) {
                    OnboardingView(
                        modelContext: Repository.sharedModelContainer.mainContext
                    ) {
                        analyticsTracker.track(.onboardingCompleted)
                        hasSeenOnboarding = true
                    }
                    .environment(\.homeCountryViewModel, homeCountryViewModel)
                    .environment(\.travelPreferencesStore, travelPreferencesStore)
                    .environment(\.premiumEntitlement, premiumEntitlement)
                    .environment(\.analyticsTracker, analyticsTracker)
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

    private func syncPremiumWidgetAccess() {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        defaults?.set(premiumEntitlement.isPremium, forKey: AppGroup.premiumAccessKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func openPendingCountryIfNeeded() {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        guard let countryCode = defaults?.string(forKey: AppGroup.pendingCountryCodeKey) else {
            return
        }

        defaults?.removeObject(forKey: AppGroup.pendingCountryCodeKey)
        deepLinkedCountryCode = countryCode.uppercased()
    }
}
