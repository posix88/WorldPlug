import Analytics
import Foundation
import Observation
import Repository

// MARK: - PackDeviceEditorRoute

/// The one push that happens *inside* the device-editor sheet.
enum PackDeviceEditorRoute: Hashable {
    case labelScanner
}

// MARK: - TripDetailViewModel

/// Owns a single trip's devices. Unlike the old result screen — which was read-only over a value
/// copy that only got persisted when the creation sheet's Save fired — this one writes every
/// change straight back to the store, because the create-then-add-devices flow has no later
/// "save the whole trip" moment.
@Observable
@MainActor
final class TripDetailViewModel {
    private let travelPreferencesStore: any TravelPreferencesStoring
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let analyticsTracker: any AnalyticsTracker
    private let requestsReviewAfterAppearance: Bool

    private(set) var trip: Trip
    private(set) var homeCountry: Country?
    private(set) var countries: [Country]

    /// The device editor is a **sheet**, not a push: this screen is itself pushed onto `TripsView`'s
    /// navigation stack, so owning a second `NavigationStack` here would nest one stack inside
    /// another (two navigation bars, a broken back gesture). The sheet carries its own stack, and
    /// `deviceEditorPath` is that stack's path — the scanner push lives inside the sheet.
    var isDeviceEditorPresented = false
    var deviceEditorPath: [PackDeviceEditorRoute] = []
    var isPremiumPaywallPresented = false
    var isTripEditorPresented = false
    var isDisclaimerPresented = false
    var scannedValues: DeviceLabelValues?

    init(
        trip: Trip,
        countries: [Country],
        homeCountry: Country?,
        travelPreferencesStore: any TravelPreferencesStoring,
        premiumEntitlement: any PremiumEntitlementProviding,
        requestsReviewAfterAppearance: Bool,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.trip = trip
        self.countries = countries
        self.homeCountry = homeCountry
        self.travelPreferencesStore = travelPreferencesStore
        self.premiumEntitlement = premiumEntitlement
        self.requestsReviewAfterAppearance = requestsReviewAfterAppearance
        self.analyticsTracker = analyticsTracker
    }

    var destination: Country? {
        countries.first(where: { $0.code == trip.countryCode })
    }

    var assessments: [DeviceSafetyAssessment] {
        guard let destination else {
            return []
        }

        return TripSafetyChecker.assessments(
            devices: trip.devices,
            homeCountry: homeCountry,
            destination: destination
        )
    }

    var isPast: Bool { trip.isPast() }

    func screenAppeared(requestReview: () -> Void) {
        analyticsTracker.track(.deviceSafetyResultViewed)
        // Pick up edits made elsewhere (another device via iCloud, or the trip editor sheet) so
        // the screen never renders a trip the store no longer agrees with.
        refreshFromStore()

        if requestsReviewAfterAppearance {
            AppReviewPrompt.requestAfterSuccessfulAction(using: requestReview)
        }
    }

    func updateCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func updateHomeCountry(_ homeCountry: Country?) {
        self.homeCountry = homeCountry
    }

    // MARK: Trip

    func editTrip() {
        isTripEditorPresented = true
    }

    func saveTrip(_ trip: Trip) {
        // The editor only owns destination/dates/name, so keep the devices this screen has.
        var updatedTrip = trip
        updatedTrip.devices = self.trip.devices
        self.trip = updatedTrip
        travelPreferencesStore.saveTrip(updatedTrip)
    }

    // MARK: Devices

    func addDevice() {
        guard premiumEntitlement.isPremium || trip.devices.isEmpty else {
            analyticsTracker.track(.tripLimitReached)
            isPremiumPaywallPresented = true
            return
        }

        deviceEditorPath = []
        scannedValues = nil
        isDeviceEditorPresented = true
    }

    /// `PackDeviceEditorView` dismisses its own sheet after saving, so this only has to persist.
    func appendDevice(_ device: PackDevice) {
        trip.devices.append(device)
        persistTrip()
        analyticsTracker.track(.tripCheckCompleted)
    }

    func removeDevice(id: UUID) {
        guard trip.devices.contains(where: { $0.id == id }) else {
            return
        }

        trip.devices.removeAll { $0.id == id }
        persistTrip()
    }

    func requestLabelScan() {
        deviceEditorPath.append(.labelScanner)
    }

    /// The sheet writes scanned values straight through the `scannedValues` binding, and
    /// `DeviceLabelScannerView` pops itself via `dismiss()`. Kept for the App Intents surface and
    /// for tests that drive a scan without a view.
    func receiveScannedValues(_ values: DeviceLabelValues) {
        scannedValues = values
    }

    // MARK: - Private

    private func persistTrip() {
        travelPreferencesStore.saveTrip(trip)
    }

    private func refreshFromStore() {
        guard let storedTrip = travelPreferencesStore.preferences.trips.first(where: { $0.id == trip.id }) else {
            return
        }

        trip = storedTrip
    }
}
