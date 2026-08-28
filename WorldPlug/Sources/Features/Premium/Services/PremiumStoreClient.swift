import StoreKit

// MARK: - PremiumStoreClient

@MainActor
struct PremiumStoreClient {
    var loadProduct: (_ productIDs: Set<String>) async throws -> PremiumProduct?
    var purchase: (_ productIDs: Set<String>) async throws -> PremiumPurchaseResult
    var hasActiveEntitlement: (_ productIDs: Set<String>) async -> Bool
    var sync: () async throws -> Void
    var transactionUpdates: () -> AsyncStream<Void>

    static var live: Self {
        PremiumStoreClient(
            loadProduct: { productIDs in
                try await Product.products(for: productIDs)
                    .first
                    .map { PremiumProduct(displayPrice: $0.displayPrice) }
            },
            purchase: { productIDs in
                guard let product = try await Product.products(for: productIDs).first else {
                    throw PremiumStoreError.productUnavailable
                }

                switch try await product.purchase() {
                case .success(let verification):
                    let transaction = try verifiedTransaction(from: verification)
                    await transaction.finish()
                    return .purchased

                case .pending:
                    return .pending

                case .userCancelled:
                    return .cancelled

                @unknown default:
                    return .cancelled
                }
            },
            hasActiveEntitlement: { productIDs in
                for await entitlement in Transaction.currentEntitlements {
                    guard let transaction = try? verifiedTransaction(from: entitlement),
                          productIDs.contains(transaction.productID),
                          transaction.revocationDate == nil,
                          !transaction.isUpgraded else {
                        continue
                    }

                    return true
                }
                return false
            },
            sync: {
                try await AppStore.sync()
            },
            transactionUpdates: {
                AsyncStream { continuation in
                    let task = Task {
                        for await update in Transaction.updates {
                            guard let transaction = try? verifiedTransaction(from: update) else {
                                continue
                            }

                            await transaction.finish()
                            continuation.yield()
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }

    private static func verifiedTransaction(
        from verification: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch verification {
        case .verified(let transaction):
            transaction
        case .unverified:
            throw PremiumStoreError.unverifiedTransaction
        }
    }
}
