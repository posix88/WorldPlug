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
    private let storeClient: PremiumStoreClient
    private var transactionUpdatesTask: Task<Void, Never>?

    private(set) var isPremium = false

    init(
        productIDs: Set<String> = [PremiumProductIDs.premium],
        storeClient: PremiumStoreClient = .live
    ) {
        self.productIDs = productIDs
        self.storeClient = storeClient
        self.transactionUpdatesTask = Task { [weak self] in
            for await _ in storeClient.transactionUpdates() {
                guard let self else {
                    return
                }

                await refreshEntitlements()
            }
        }
    }

    func refreshEntitlements() async {
        isPremium = await storeClient.hasActiveEntitlement(productIDs)
    }

    func premiumProduct() async throws -> PremiumProduct? {
        try await storeClient.loadProduct(productIDs)
    }

    func purchasePremium() async throws -> PremiumPurchaseResult {
        let result = try await storeClient.purchase(productIDs)
        if result == .purchased {
            await refreshEntitlements()
        }
        return result
    }

    func restorePurchases() async throws {
        try await storeClient.sync()
        await refreshEntitlements()
    }
}

// MARK: - PremiumStoreError

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
