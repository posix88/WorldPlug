import Observation

@Observable
@MainActor
final class DeviceLabelScannerViewModel {
    func recognizedValues(in text: String) -> DeviceLabelValues? {
        let values = DeviceLabelParser.values(in: text)
        return values.voltage.isEmpty ? nil : values
    }
}
