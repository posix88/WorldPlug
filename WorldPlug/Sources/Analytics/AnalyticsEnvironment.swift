import Analytics
import SwiftUI

extension EnvironmentValues {
    @Entry var analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker()
}
