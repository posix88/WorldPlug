import Foundation
import Observation
import Repository

// MARK: - TripCheckEditorRoute

enum TripCheckEditorRoute: Hashable {
    case deviceEditor
    case labelScanner
}

// MARK: - TripCheckEditorViewModel

@Observable
@MainActor
final class TripCheckEditorViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding

    var trip: Trip
    var navigationPath: [TripCheckEditorRoute] = []
    var isPremiumPaywallPresented = false
    var scannedValues: DeviceLabelValues?

    /// A new trip starts with **no** destination. There used to be a prefill that fell back to
    /// `countries.first`, which silently proposed Andorra; an unset destination keeps `canSave`
    /// false until the user picks one on purpose.
    init(premiumEntitlement: any PremiumEntitlementProviding) {
        self.trip = Trip(countryCode: "")
        self.premiumEntitlement = premiumEntitlement
    }

    var canSave: Bool {
        !trip.countryCode.isEmpty && !trip.devices.isEmpty
    }

    func save() -> Trip {
        trip
    }

    func addDevice() {
        guard premiumEntitlement.isPremium || trip.devices.isEmpty else {
            isPremiumPaywallPresented = true
            return
        }

        navigationPath.append(.deviceEditor)
    }

    func appendDevice(_ device: PackDevice) {
        trip.devices.append(device)
    }

    func removeDevice(id: UUID) {
        trip.devices.removeAll { $0.id == id }
    }

    func requestLabelScan() {
        navigationPath.append(.labelScanner)
    }

    func receiveScannedValues(_ values: DeviceLabelValues) {
        scannedValues = values
    }
}
