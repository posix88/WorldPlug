import Foundation
import Observation
import Repository

// MARK: - TripCheckEditorRoute

enum TripCheckEditorRoute: Hashable {
    case deviceEditor
    case labelScanner
}

@Observable
@MainActor
final class TripCheckEditorViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding

    var tripCheck: TripCheck
    var returnDate: Date
    var navigationPath: [TripCheckEditorRoute] = []
    var isPremiumPaywallPresented = false
    var scannedValues: DeviceLabelValues?

    init(countries: [Country], premiumEntitlement: any PremiumEntitlementProviding) {
        let initial = TripCheck(countryCode: countries.first?.code ?? "")
        self.tripCheck = initial
        self.returnDate = initial.returnDate
        self.premiumEntitlement = premiumEntitlement
    }

    var canSave: Bool {
        !tripCheck.countryCode.isEmpty && !tripCheck.devices.isEmpty
    }

    func save() -> TripCheck {
        tripCheck.returnDate = returnDate
        return tripCheck
    }

    func addDevice() {
        guard premiumEntitlement.isPremium || tripCheck.devices.isEmpty else {
            isPremiumPaywallPresented = true
            return
        }
        navigationPath.append(.deviceEditor)
    }

    func appendDevice(_ device: PackDevice) {
        tripCheck.devices.append(device)
    }

    func removeDevice(id: UUID) {
        tripCheck.devices.removeAll { $0.id == id }
    }

    func requestLabelScan() {
        navigationPath.append(.labelScanner)
    }

    func receiveScannedValues(_ values: DeviceLabelValues) {
        scannedValues = values
    }
}
