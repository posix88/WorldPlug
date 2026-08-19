import Observation
import UIKit

// MARK: - DeviceLabelScannerState

enum DeviceLabelScannerState: Equatable {
    case idle
    case analyzing
    case noValuesFound
}

// MARK: - DeviceLabelScannerViewModel

@Observable
@MainActor
final class DeviceLabelScannerViewModel {
    private let interpreter: any DeviceLabelInterpreting

    private(set) var state: DeviceLabelScannerState = .idle
    /// Set when the on-device model throws and analysis falls back to deterministic Vision text
    /// parsing. The fallback itself is intentional graceful degradation, but with nothing
    /// recording *why* it happened this would otherwise be invisible in the field — the view
    /// reads this after `analyze(image:fallbackText:)` returns and reports it to analytics.
    private(set) var lastSmartAnalysisFailureReason: String?

    init(interpreter: any DeviceLabelInterpreting) {
        self.interpreter = interpreter
    }

    var usesFoundationModel: Bool {
        interpreter.isAvailable
    }

    /// Marks analysis as started *before* any `await` (e.g. a camera capture) runs, so the
    /// UI can disable re-entrant taps for the whole round trip — not just from the point
    /// `analyze(image:fallbackText:)` itself is finally called. See `DeviceLabelScannerView`.
    func beginAnalyzing() {
        state = .analyzing
    }

    func recognizedValues(in text: String) -> DeviceLabelValues? {
        let values = DeviceLabelParser.values(in: text)
        return values.voltage.isEmpty ? nil : values
    }

    func analyze(image: UIImage?, fallbackText: String) async -> DeviceLabelValues? {
        state = .analyzing
        lastSmartAnalysisFailureReason = nil

        if interpreter.isAvailable, let image {
            do {
                try Task.checkCancellation()
                if let values = try await interpreter.values(in: image) {
                    state = .idle
                    return values
                }
            } catch is CancellationError {
                state = .idle
                return nil
            } catch {
                // Continue with deterministic Vision text parsing.
                lastSmartAnalysisFailureReason = String(describing: error)
            }
        }

        if let values = recognizedValues(in: fallbackText) {
            state = .idle
            return values
        }

        state = .noValuesFound
        return nil
    }
}
