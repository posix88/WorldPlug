import Analytics
import Observation

// MARK: - PremiumPaywallViewModel

@Observable
@MainActor
final class PremiumPaywallViewModel {
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let analyticsTracker: any AnalyticsTracker

    let source: PremiumPaywallSource
    var isPurchasing = false
    var errorMessage: String?
    var premiumPrice: String?

    init(
        source: PremiumPaywallSource,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.source = source
        self.premiumEntitlement = premiumEntitlement
        self.analyticsTracker = analyticsTracker
    }

    var isPremium: Bool { premiumEntitlement.isPremium }

    func screenAppeared() {
        analyticsTracker.screen(.premiumPaywall)
        analyticsTracker.track(
            .premiumPaywallPresented,
            parameters: ["source": .string(source.rawValue)]
        )
    }

    func loadProduct() async {
        premiumPrice = try? await premiumEntitlement.premiumProduct()?.displayPrice
    }

    func purchase() async {
        analyticsTracker.track(.premiumPurchaseStarted)
        await perform {
            let result = try await premiumEntitlement.purchasePremium()
            if result == .purchased {
                analyticsTracker.track(.premiumPurchaseCompleted)
            }
        }
    }

    func restore() async {
        analyticsTracker.track(.premiumRestoreStarted)
        await perform {
            try await premiumEntitlement.restorePurchases()
            analyticsTracker.track(.premiumRestoreCompleted)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func perform(_ operation: () async throws -> Void) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
