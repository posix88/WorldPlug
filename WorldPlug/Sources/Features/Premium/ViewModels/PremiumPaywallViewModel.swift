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
    /// Set when StoreKit returns `.pending` (e.g. Ask to Buy) — the purchase wasn't declined or
    /// completed, it's just waiting on approval, so this must not be shown as an error.
    var isPurchasePending = false
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
            switch result {
            case .purchased:
                analyticsTracker.track(.premiumPurchaseCompleted)
            case .pending:
                isPurchasePending = true
            case .cancelled:
                break
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

    func clearPendingNotice() {
        isPurchasePending = false
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
