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

    init(interpreter: any DeviceLabelInterpreting) {
        self.interpreter = interpreter
    }

    var usesFoundationModel: Bool {
        interpreter.isAvailable
    }

    func recognizedValues(in text: String) -> DeviceLabelValues? {
        let values = DeviceLabelParser.values(in: text)
        return values.voltage.isEmpty ? nil : values
    }

    func analyze(image: UIImage?, fallbackText: String) async -> DeviceLabelValues? {
        state = .analyzing

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
