import SwiftUI

// MARK: - VoltlyWatchApp

@main
struct VoltlyWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var catalog: WatchCatalogViewModel
    @State private var preferencesStore: WatchTravelPreferencesStore
    @State private var premiumEntitlement: WatchPremiumEntitlement

    init() {
        let catalog = WatchCatalogViewModel()
        let preferencesStore = WatchTravelPreferencesStore()
        let premiumEntitlement = WatchPremiumEntitlement()
        _catalog = State(initialValue: catalog)
        _preferencesStore = State(initialValue: preferencesStore)
        _premiumEntitlement = State(initialValue: premiumEntitlement)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView(
                catalog: catalog,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
            .task {
                await premiumEntitlement.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else {
                    return
                }
                preferencesStore.reloadFromICloud()
                Task {
                    await premiumEntitlement.refresh()
                }
            }
        }
    }
}
