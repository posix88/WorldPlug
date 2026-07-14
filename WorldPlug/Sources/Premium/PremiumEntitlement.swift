import Observation
import SwiftUI

// MARK: - PremiumEntitlementProviding

/// Single source of truth for premium access.
/// StoreKit will replace the development implementation without changing feature code.
protocol PremiumEntitlementProviding: AnyObject {
    @MainActor var isPremium: Bool { get }
}

// MARK: - DevelopmentPremiumEntitlement

@Observable
@MainActor
final class DevelopmentPremiumEntitlement: PremiumEntitlementProviding {
    private(set) var isPremium = false
}

// MARK: - NullPremiumEntitlement

final class NullPremiumEntitlement: PremiumEntitlementProviding {
    @MainActor var isPremium: Bool { false }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var premiumEntitlement: any PremiumEntitlementProviding = NullPremiumEntitlement()
}
