import SwiftUI
import VisionKit

struct DeviceLabelValues: Equatable {
    let voltage: String
    let frequency: String
}

struct DeviceLabelScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onRecognized: (DeviceLabelValues) -> Void

    var body: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DeviceLabelDataScanner { text in
                    let values = DeviceLabelParser.values(in: text)
                    guard !values.voltage.isEmpty else { return }
                    onRecognized(values)
                    dismiss()
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView(
                    LocalizationKeys.tripCheckScanUnavailable.localized,
                    systemImage: "camera.fill",
                    description: Text(LocalizationKeys.tripCheckScanUnavailableDescription.localized)
                )
            }
        }
        .navigationTitle(LocalizationKeys.tripCheckScanLabel.localized)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .accessibilityLabel(LocalizationKeys.generalClose.localized)
            }
        }
    }
}

private struct DeviceLabelDataScanner: UIViewControllerRepresentable {
    let onRecognized: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onRecognized: onRecognized) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text(languages: ["en", "it"])],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onRecognized: (String) -> Void

        init(onRecognized: @escaping (String) -> Void) {
            self.onRecognized = onRecognized
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard case .text(let text) = item else { return }
            onRecognized(text.transcript)
        }
    }
}

private enum DeviceLabelParser {
    static func values(in text: String) -> DeviceLabelValues {
        let normalized = text.replacingOccurrences(of: "–", with: "-")
        return DeviceLabelValues(
            voltage: firstMatch(in: normalized, pattern: #"\b\d{2,3}\s*(?:-|to|/)\s*\d{2,3}\s*V(?:AC)?\b|\b\d{2,3}\s*V(?:AC)?\b"#),
            frequency: firstMatch(in: normalized, pattern: #"\b(?:\d{2}\s*(?:/|-)\s*\d{2}|\d{2})\s*Hz\b"#)
        )
    }

    private static func firstMatch(in text: String, pattern: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return ""
        }
        return String(text[range])
    }
}

#if DEBUG
#Preview("Label scanner") {
    NavigationStack {
        DeviceLabelScannerView { _ in }
    }
}
#endif
