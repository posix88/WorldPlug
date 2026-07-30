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

    var tripCheck: TripCheck
    var navigationPath: [TripCheckEditorRoute] = []
    var isPremiumPaywallPresented = false
    var scannedValues: DeviceLabelValues?

    init(
        countries: [Country],
        initialCountryCode: String? = nil,
        premiumEntitlement: any PremiumEntitlementProviding
    ) {
        let countryCode = initialCountryCode.flatMap { code in
            countries.contains(where: { $0.code == code }) ? code : nil
        } ?? countries.first?.code ?? ""
        self.tripCheck = TripCheck(countryCode: countryCode)
        self.premiumEntitlement = premiumEntitlement
    }

    var canSave: Bool {
        !tripCheck.countryCode.isEmpty && !tripCheck.devices.isEmpty
    }

    func save() -> TripCheck {
        tripCheck
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
