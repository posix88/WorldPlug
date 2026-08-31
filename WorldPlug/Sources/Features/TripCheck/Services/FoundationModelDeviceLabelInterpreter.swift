import FoundationModels
import UIKit
import Vision

// MARK: - DeviceLabelInterpreting

protocol DeviceLabelInterpreting: Sendable {
    var isAvailable: Bool { get }

    func values(in image: UIImage) async throws -> DeviceLabelValues?
}

// MARK: - FoundationModelDeviceLabelInterpreter

struct FoundationModelDeviceLabelInterpreter: DeviceLabelInterpreting {
    var isAvailable: Bool {
       SystemLanguageModel.default.isAvailable
    }

    func values(in image: UIImage) async throws -> DeviceLabelValues? {
        let instructions = Instructions {
            """
            Read electrical input ratings from device labels.
            Extract only the INPUT voltage and frequency printed in the image.
            Never infer, convert, or invent a missing value.
            Preserve numeric ranges and units.
            Return an empty string when a value is absent or unreadable.
            """
        }
        #if targetEnvironment(simulator)
        /// Xcode 27 Beta 4 doesn't include Vision's Foundation Models tools in the simulator SDK.
        let session = LanguageModelSession(instructions: instructions)
        #else
        let session = LanguageModelSession(
            tools: [OCRTool()],
            instructions: instructions
        )
        #endif
        let response = try await session.respond(generating: ElectricalInputRating.self) {
            """
            Extract the device input voltage and frequency from this electrical label.
            Ignore output ratings.
            """
            Attachment(image).label("Device electrical rating label")
        }
        let parsedValues = DeviceLabelParser.values(
            in: "\(response.content.voltage)\n\(response.content.frequency)"
        )

        return parsedValues.voltage.isEmpty ? nil : parsedValues
    }
}

// MARK: - ElectricalInputRating

@Generable
private struct ElectricalInputRating {
    @Guide(description: "Exact INPUT voltage with unit, such as 100-240V. Empty when absent or unreadable.")
    var voltage: String

    @Guide(description: "Exact INPUT frequency with unit, such as 50/60Hz. Empty when absent or unreadable.")
    var frequency: String
}
