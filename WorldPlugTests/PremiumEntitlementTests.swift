import Testing
@testable import WorldPlug

@MainActor
struct PremiumEntitlementTests {
    @Test
    func developmentEntitlementIsLocked() {
        let entitlement = DevelopmentPremiumEntitlement()

        #expect(entitlement.isPremium == false)
    }
}
