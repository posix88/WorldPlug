import Testing
@testable import WorldPlug

// MARK: - PremiumEntitlementTests

@Suite("Premium entitlement")
@MainActor
struct PremiumEntitlementTests {
    @Test("successful purchase refreshes premium state")
    func successfulPurchaseRefreshesState() async throws {
        let recorder = PremiumStoreRecorder(purchaseResult: .purchased, entitlementResults: [true])
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        let result = try await entitlement.purchasePremium()

        #expect(result == .purchased)
        #expect(entitlement.isPremium)
        #expect(recorder.purchaseCalls == 1)
        #expect(recorder.entitlementCalls == 1)
    }

    @Test(arguments: [PremiumPurchaseResult.cancelled, .pending])
    func incompletePurchaseDoesNotRefresh(result: PremiumPurchaseResult) async throws {
        let recorder = PremiumStoreRecorder(purchaseResult: result, entitlementResults: [true])
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        #expect(try await entitlement.purchasePremium() == result)
        #expect(!entitlement.isPremium)
        #expect(recorder.entitlementCalls == 0)
    }

    @Test("purchase error is propagated")
    func purchaseErrorIsPropagated() async {
        let recorder = PremiumStoreRecorder(purchaseError: TestStoreError.failed)
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        await #expect(throws: TestStoreError.failed) {
            try await entitlement.purchasePremium()
        }
        #expect(recorder.entitlementCalls == 0)
    }

    @Test("restore refreshes premium state")
    func restoreRefreshesState() async throws {
        let recorder = PremiumStoreRecorder(entitlementResults: [true])
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        try await entitlement.restorePurchases()

        #expect(recorder.syncCalls == 1)
        #expect(recorder.entitlementCalls == 1)
        #expect(entitlement.isPremium)
    }

    @Test("restore error preserves state and skips refresh")
    func restoreErrorPreservesState() async {
        let recorder = PremiumStoreRecorder(entitlementResults: [true], syncError: TestStoreError.failed)
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        await #expect(throws: TestStoreError.failed) {
            try await entitlement.restorePurchases()
        }
        #expect(!entitlement.isPremium)
        #expect(recorder.entitlementCalls == 0)
    }

    @Test("refresh removes expired premium state")
    func refreshRemovesPremiumState() async {
        let recorder = PremiumStoreRecorder(entitlementResults: [true, false])
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        await entitlement.refreshEntitlements()
        #expect(entitlement.isPremium)

        await entitlement.refreshEntitlements()
        #expect(!entitlement.isPremium)
    }

    @Test("product loading returns price and propagates error")
    func productLoading() async throws {
        let recorder = PremiumStoreRecorder(product: PremiumProduct(displayPrice: "$4.99"))
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        #expect(try await entitlement.premiumProduct()?.displayPrice == "$4.99")

        recorder.loadError = TestStoreError.failed
        await #expect(throws: TestStoreError.failed) {
            try await entitlement.premiumProduct()
        }
    }

    @Test("transaction update refreshes premium state")
    func transactionUpdateRefreshesState() async {
        let recorder = PremiumStoreRecorder(entitlementResults: [true])
        let entitlement = StoreKitPremiumEntitlement(storeClient: recorder.client)

        recorder.sendTransactionUpdate()
        for _ in 0 ..< 100 where recorder.entitlementCalls == 0 {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(entitlement.isPremium)
        #expect(recorder.entitlementCalls == 1)
    }

    @Test("null entitlement stays locked")
    func nullEntitlementIsLocked() {
        #expect(!NullPremiumEntitlement().isPremium)
    }
}

// MARK: - PremiumStoreRecorder

@MainActor
private final class PremiumStoreRecorder {
    var product: PremiumProduct?
    var purchaseResult: PremiumPurchaseResult
    var entitlementResults: [Bool]
    var loadError: (any Error)?
    var purchaseError: (any Error)?
    var syncError: (any Error)?
    private(set) var purchaseCalls = 0
    private(set) var entitlementCalls = 0
    private(set) var syncCalls = 0
    private let updates: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init(
        product: PremiumProduct? = nil,
        purchaseResult: PremiumPurchaseResult = .cancelled,
        entitlementResults: [Bool] = [],
        loadError: (any Error)? = nil,
        purchaseError: (any Error)? = nil,
        syncError: (any Error)? = nil
    ) {
        self.product = product
        self.purchaseResult = purchaseResult
        self.entitlementResults = entitlementResults
        self.loadError = loadError
        self.purchaseError = purchaseError
        self.syncError = syncError
        (self.updates, self.continuation) = AsyncStream.makeStream()
    }

    deinit {
        continuation.finish()
    }

    var client: PremiumStoreClient {
        PremiumStoreClient(
            loadProduct: { [weak self] _ in
                guard let self else {
                    return nil
                }

                if let loadError {
                    throw loadError
                }
                return product
            },
            purchase: { [weak self] _ in
                guard let self else {
                    return .cancelled
                }

                purchaseCalls += 1
                if let purchaseError {
                    throw purchaseError
                }
                return purchaseResult
            },
            hasActiveEntitlement: { [weak self] _ in
                guard let self else {
                    return false
                }

                entitlementCalls += 1
                return entitlementResults.isEmpty ? false : entitlementResults.removeFirst()
            },
            sync: { [weak self] in
                guard let self else {
                    return
                }

                syncCalls += 1
                if let syncError {
                    throw syncError
                }
            },
            transactionUpdates: { [updates] in updates }
        )
    }

    func sendTransactionUpdate() {
        continuation.yield()
    }
}

// MARK: - TestStoreError

private enum TestStoreError: Error {
    case failed
}
