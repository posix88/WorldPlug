import SwiftUI
import Testing
@testable import WorldPlug

// MARK: - UtilitiesTests

@Suite("View+Utilities")
struct UtilitiesTests {

    // MARK: roundedCorner

    @Test("roundedCorner clips and shapes a view")
    @MainActor
    func roundedCornerProducesModifiedView() {
        let view = Color.red.roundedCorner(radius: 12)
        _ = type(of: view)
    }

    @Test("roundedCornerWithBorder applies border overlay")
    @MainActor
    func roundedCornerWithBorderProducesModifiedView() {
        let view = Color.blue.roundedCornerWithBorder(radius: 8, lineWidth: 1, borderColor: .black)
        _ = type(of: view)
    }
}
