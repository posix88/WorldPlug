import Observation
import StoreKit

// MARK: - WatchPremiumEntitlement

@Observable
@MainActor
final class WatchPremiumEntitlement {
    private static let premiumProductID = "com.posix88.voltly.premium"

    private(set) var isPremium = false

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
    }

    func refresh() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case let .verified(transaction) = entitlement,
                  transaction.productID == Self.premiumProductID,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else {
                continue
            }

            isPremium = true
            return
        }

        isPremium = false
    }
}
