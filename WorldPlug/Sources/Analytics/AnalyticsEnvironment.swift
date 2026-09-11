import Analytics
import SwiftUI

extension EnvironmentValues {
    /// Backed by a `static let` rather than written inline as `NoopAnalyticsTracker()`.
    ///
    /// `@Entry` always wraps its default expression in a computed getter, so an inline
    /// initializer allocates a fresh instance on *every* read that falls back to the default.
    /// Class references compare by identity, so each of those reads looks like a change, and any
    /// ancestor write to any environment key invalidates every falling-back reader.
    ///
    /// Nothing falls back today — the app root injects the real tracker above every reader — so
    /// this is a regression guard rather than a fix for a live cost. It stops mattering the
    /// moment someone adds a reader outside that subtree.
    @Entry var analyticsTracker: any AnalyticsTracker = defaultAnalyticsTracker

    private static let defaultAnalyticsTracker = NoopAnalyticsTracker()
}
