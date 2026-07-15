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
    @State private var deepLinkedCountryCode: String?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let travelPreferencesStore = ICloudTravelPreferencesStore()
        _travelPreferencesStore = State(initialValue: travelPreferencesStore)
        _homeCountryViewModel = State(
            initialValue: HomeCountryViewModel(
                travelPreferencesStore: travelPreferencesStore,
                modelContext: Repository.sharedModelContainer.mainContext
            )
        )
        _premiumEntitlement = State(initialValue: StoreKitPremiumEntitlement())
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
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        homeCountryViewModel.refreshHomeCountry()
                    }
                }
                .onAppear(perform: syncPremiumWidgetAccess)
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
                        hasSeenOnboarding = true
                    }
                    .environment(\.homeCountryViewModel, homeCountryViewModel)
                    .environment(\.travelPreferencesStore, travelPreferencesStore)
                    .environment(\.premiumEntitlement, premiumEntitlement)
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
}
