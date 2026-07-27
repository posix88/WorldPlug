import Observation
import StoreKit
import SwiftUI

// MARK: - PremiumEntitlementProviding

/// Single source of truth for premium access.
protocol PremiumEntitlementProviding: AnyObject {
    @MainActor var isPremium: Bool { get }
    @MainActor func refreshEntitlements() async
    @MainActor func premiumProduct() async throws -> PremiumProduct?
    @MainActor func purchasePremium() async throws -> PremiumPurchaseResult
    @MainActor func restorePurchases() async throws
}

// MARK: - PremiumProduct

struct PremiumProduct: Equatable {
    let displayPrice: String
}

// MARK: - PremiumPurchaseResult

enum PremiumPurchaseResult: Equatable {
    case purchased
    case pending
    case cancelled
}

// MARK: - PremiumProductIDs

enum PremiumProductIDs {
    /// Replace with the product identifier configured in App Store Connect.
    static let premium = "com.posix88.voltly.premium"
}

// MARK: - StoreKitPremiumEntitlement

@Observable
@MainActor
final class StoreKitPremiumEntitlement: PremiumEntitlementProviding {
    private let productIDs: Set<String>
    private var transactionUpdatesTask: Task<Void, Never>?

    private(set) var isPremium = false

    init(productIDs: Set<String> = [PremiumProductIDs.premium]) {
        self.productIDs = productIDs
        transactionUpdatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else {
                    return
                }

                guard let transaction = try? Self.verifiedTransaction(from: update) else {
                    continue
                }

                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    func refreshEntitlements() async {
        var hasPremiumEntitlement = false

        for await entitlement in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? Self.verifiedTransaction(from: entitlement),
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else {
                continue
            }

            hasPremiumEntitlement = true
            break
        }

        isPremium = hasPremiumEntitlement
    }

    func premiumProduct() async throws -> PremiumProduct? {
        try await storeKitProduct().map { PremiumProduct(displayPrice: $0.displayPrice) }
    }

    func purchasePremium() async throws -> PremiumPurchaseResult {
        guard let product = try await storeKitProduct() else {
            throw PremiumStoreError.productUnavailable
        }

        switch try await product.purchase() {
        case .success(let verification):
            let transaction = try Self.verifiedTransaction(from: verification)
            await transaction.finish()
            await refreshEntitlements()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    private func storeKitProduct() async throws -> Product? {
        try await Product.products(for: productIDs).first
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private static func verifiedTransaction(
        from verification: VerificationResult<StoreKit.Transaction>
    ) throws -> StoreKit.Transaction {
        switch verification {
        case .verified(let transaction):
            transaction
        case .unverified:
            throw PremiumStoreError.unverifiedTransaction
        }
    }
}

enum PremiumStoreError: LocalizedError {
    case productUnavailable
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            "Premium is not available right now."
        case .unverifiedTransaction:
            "Could not verify this purchase."
        }
    }
}

// MARK: - NullPremiumEntitlement

final class NullPremiumEntitlement: PremiumEntitlementProviding {
    @MainActor var isPremium: Bool { false }
    @MainActor func refreshEntitlements() async {}
    @MainActor func premiumProduct() async throws -> PremiumProduct? { nil }
    @MainActor func purchasePremium() async throws -> PremiumPurchaseResult { .cancelled }
    @MainActor func restorePurchases() async throws {}
}

#if DEBUG
@Observable
@MainActor
final class PreviewPremiumEntitlement: PremiumEntitlementProviding {
    var isPremium: Bool

    init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    func refreshEntitlements() async {}
    func premiumProduct() async throws -> PremiumProduct? { nil }
    func purchasePremium() async throws -> PremiumPurchaseResult { .purchased }
    func restorePurchases() async throws {}
}
#endif

// MARK: - Environment

extension EnvironmentValues {
    @Entry var premiumEntitlement: any PremiumEntitlementProviding = NullPremiumEntitlement()
}
