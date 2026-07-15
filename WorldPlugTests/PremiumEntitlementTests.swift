import Testing
@testable import WorldPlug

@MainActor
struct PremiumEntitlementTests {
    @Test
    func nullEntitlementIsLocked() {
        let entitlement = NullPremiumEntitlement()

        #expect(entitlement.isPremium == false)
    }
}
