import SwiftUI
import VisionKit

// MARK: - DeviceLabelScannerView

struct DeviceLabelScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DeviceLabelScannerViewModel
    @State private var camera = DeviceLabelScannerCamera()
    @State private var recognizedText = ""
    let onRecognized: (DeviceLabelValues) -> Void

    init(
        interpreter: any DeviceLabelInterpreting,
        onRecognized: @escaping (DeviceLabelValues) -> Void
    ) {
        _viewModel = State(initialValue: DeviceLabelScannerViewModel(interpreter: interpreter))
        self.onRecognized = onRecognized
    }

    var body: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                ZStack(alignment: .bottom) {
                    DeviceLabelDataScanner(
                        camera: camera,
                        onRecognizedTextChanged: { recognizedText = $0 },
                        onRecognizedTextTapped: finishWithRecognizedText
                    )
                    .ignoresSafeArea(edges: .bottom)

                    scannerControls
                }
            } else {
                ContentUnavailableView(
                    LocalizationKeys.tripCheckScanUnavailable.localized,
                    systemImage: "camera.fill",
                    description: Text(LocalizationKeys.tripCheckScanUnavailableDescription.localized)
                )
            }
        }
        .navigationTitle(LocalizationKeys.tripCheckScanLabel.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scannerControls: some View {
        VStack(spacing: .md) {
            if viewModel.state == .noValuesFound {
                Label(
                    LocalizationKeys.tripCheckScanNoValues.localized,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
            } else {
                Text(
                    viewModel.usesFoundationModel
                        ? LocalizationKeys.tripCheckScanSmartHint.localized
                        : LocalizationKeys.tripCheckScanLabelHint.localized
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await analyzeLabel()
                }
            } label: {
                Group {
                    if viewModel.state == .analyzing {
                        ProgressView()
                    } else {
                        Label(
                            LocalizationKeys.tripCheckScanAnalyze.localized,
                            systemImage: viewModel.usesFoundationModel ? "sparkles" : "viewfinder"
                        )
                    }
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state == .analyzing)
            .accessibilityHint(LocalizationKeys.tripCheckScanLabelHint.localized)
        }
        .padding(.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, .xxl)
        .padding(.bottom, .lg)
    }

    private func analyzeLabel() async {
        let image = viewModel.usesFoundationModel ? try? await camera.capturePhoto() : nil
        guard let values = await viewModel.analyze(image: image, fallbackText: recognizedText) else {
            return
        }

        finish(with: values)
    }

    private func finishWithRecognizedText(_ text: String) {
        guard let values = viewModel.recognizedValues(in: text) else {
            return
        }

        finish(with: values)
    }

    private func finish(with values: DeviceLabelValues) {
        onRecognized(values)
        dismiss()
    }
}

// MARK: - DeviceLabelScannerCamera

@Observable
@MainActor
private final class DeviceLabelScannerCamera {
    weak var scanner: DataScannerViewController?

    func capturePhoto() async throws -> UIImage {
        guard let scanner else {
            throw DeviceLabelScannerCameraError.notReady
        }

        return try await scanner.capturePhoto()
    }
}

// MARK: - DeviceLabelScannerCameraError

private enum DeviceLabelScannerCameraError: Error {
    case notReady
}

// MARK: - DeviceLabelDataScanner

private struct DeviceLabelDataScanner: UIViewControllerRepresentable {
    let camera: DeviceLabelScannerCamera
    let onRecognizedTextChanged: (String) -> Void
    let onRecognizedTextTapped: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onRecognizedTextChanged: onRecognizedTextChanged,
            onRecognizedTextTapped: onRecognizedTextTapped
        )
    }

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
        camera.scanner = scanner
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(
        _ uiViewController: DataScannerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.stopScanning()
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onRecognizedTextChanged: (String) -> Void
        let onRecognizedTextTapped: (String) -> Void

        init(
            onRecognizedTextChanged: @escaping (String) -> Void,
            onRecognizedTextTapped: @escaping (String) -> Void
        ) {
            self.onRecognizedTextChanged = onRecognizedTextChanged
            self.onRecognizedTextTapped = onRecognizedTextTapped
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard case .text(let text) = item else {
                return
            }

            onRecognizedTextTapped(text.transcript)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            recognizedItemsChanged(allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            recognizedItemsChanged(allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            recognizedItemsChanged(allItems)
        }

        private func recognizedItemsChanged(_ items: [RecognizedItem]) {
            let text = items.compactMap { item -> String? in
                guard case .text(let text) = item else {
                    return nil
                }

                return text.transcript
            }
            .joined(separator: "\n")
            onRecognizedTextChanged(text)
        }
    }
}

#if DEBUG
#Preview("Label scanner") {
    NavigationStack {
        DeviceLabelScannerView(
            interpreter: FoundationModelDeviceLabelInterpreter(),
            onRecognized: { _ in }
        )
    }
}
#endif
