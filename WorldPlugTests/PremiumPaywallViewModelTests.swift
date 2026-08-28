import Analytics
import Testing
@testable import WorldPlug

// MARK: - PremiumPaywallViewModelTests

@Suite("Premium paywall view model")
@MainActor
struct PremiumPaywallViewModelTests {
    @Test("loads premium price")
    func loadsPrice() async {
        let entitlement = PremiumEntitlementStub(product: PremiumProduct(displayPrice: "$4.99"))
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.loadProduct()

        #expect(viewModel.premiumPrice == "$4.99")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("product load error is visible")
    func productLoadErrorIsVisible() async {
        let entitlement = PremiumEntitlementStub(productError: TestPaywallError.failed)
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.loadProduct()

        #expect(viewModel.premiumPrice == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("successful product reload clears stale error")
    func successfulProductReloadClearsError() async {
        let entitlement = PremiumEntitlementStub(productError: TestPaywallError.failed)
        let viewModel = makeViewModel(entitlement: entitlement)
        await viewModel.loadProduct()

        entitlement.productError = nil
        entitlement.product = PremiumProduct(displayPrice: "$4.99")
        viewModel.isPurchasePending = true
        await viewModel.loadProduct()

        #expect(viewModel.premiumPrice == "$4.99")
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isPurchasePending)
    }

    @Test("failed product reload clears stale price")
    func failedProductReloadClearsPrice() async {
        let entitlement = PremiumEntitlementStub(product: PremiumProduct(displayPrice: "$4.99"))
        let viewModel = makeViewModel(entitlement: entitlement)
        await viewModel.loadProduct()

        entitlement.productError = TestPaywallError.failed
        await viewModel.loadProduct()

        #expect(viewModel.premiumPrice == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("successful purchase clears stale state")
    func successfulPurchaseClearsStaleState() async {
        let entitlement = PremiumEntitlementStub(purchaseResult: .purchased)
        let viewModel = makeViewModel(entitlement: entitlement)
        viewModel.errorMessage = "Old error"
        viewModel.isPurchasePending = true

        await viewModel.purchase()

        #expect(!viewModel.isPurchasing)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isPurchasePending)
    }

    @Test("pending purchase shows pending notice")
    func pendingPurchaseShowsNotice() async {
        let entitlement = PremiumEntitlementStub(purchaseResult: .pending)
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.purchase()

        #expect(viewModel.isPurchasePending)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isPurchasing)
    }

    @Test("cancelled purchase is not an error")
    func cancelledPurchaseIsNotError() async {
        let entitlement = PremiumEntitlementStub(purchaseResult: .cancelled)
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.purchase()

        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isPurchasePending)
    }

    @Test("purchase error is visible")
    func purchaseErrorIsVisible() async {
        let entitlement = PremiumEntitlementStub(purchaseError: TestPaywallError.failed)
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.purchase()

        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isPurchasing)
    }

    @Test("restore success and error update state")
    func restoreOutcomes() async {
        let entitlement = PremiumEntitlementStub()
        let viewModel = makeViewModel(entitlement: entitlement)

        await viewModel.restore()
        #expect(entitlement.restoreCalls == 1)
        #expect(viewModel.errorMessage == nil)

        entitlement.restoreError = TestPaywallError.failed
        await viewModel.restore()
        #expect(entitlement.restoreCalls == 2)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isPurchasing)
    }

    private func makeViewModel(entitlement: PremiumEntitlementStub) -> PremiumPaywallViewModel {
        PremiumPaywallViewModel(
            source: .savedCountries,
            premiumEntitlement: entitlement,
            analyticsTracker: NoopAnalyticsTracker()
        )
    }
}

// MARK: - PremiumEntitlementStub

@MainActor
private final class PremiumEntitlementStub: PremiumEntitlementProviding {
    var isPremium = false
    var product: PremiumProduct?
    var purchaseResult: PremiumPurchaseResult
    var productError: (any Error)?
    var purchaseError: (any Error)?
    var restoreError: (any Error)?
    private(set) var restoreCalls = 0

    init(
        product: PremiumProduct? = nil,
        purchaseResult: PremiumPurchaseResult = .cancelled,
        productError: (any Error)? = nil,
        purchaseError: (any Error)? = nil,
        restoreError: (any Error)? = nil
    ) {
        self.product = product
        self.purchaseResult = purchaseResult
        self.productError = productError
        self.purchaseError = purchaseError
        self.restoreError = restoreError
    }

    func refreshEntitlements() async {}

    func premiumProduct() async throws -> PremiumProduct? {
        if let productError {
            throw productError
        }
        return product
    }

    func purchasePremium() async throws -> PremiumPurchaseResult {
        if let purchaseError {
            throw purchaseError
        }
        return purchaseResult
    }

    func restorePurchases() async throws {
        restoreCalls += 1
        if let restoreError {
            throw restoreError
        }
    }
}

// MARK: - TestPaywallError

private enum TestPaywallError: Error {
    case failed
}
