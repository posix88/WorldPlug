import Repository
import SwiftUI

// MARK: - VoltageCompatibility

enum VoltageCompatibility {
    /// `minimumTolerance` is an absolute floor (in volts) applied on top of the percentage-based
    /// tolerance below, so very low nominal voltages still get a sane minimum band.
    static func isCompatible(_ lhs: String, _ rhs: String, minimumTolerance: Int = 10) -> Bool {
        let lhsVoltages = parseVoltages(lhs)
        let rhsVoltages = parseVoltages(rhs)

        guard !lhsVoltages.isEmpty, !rhsVoltages.isEmpty else {
            return true
        }

        if Set(lhsVoltages) == Set(rhsVoltages) {
            return true
        }

        return lhsVoltages.allSatisfy { lhsVoltage in
            rhsVoltages.allSatisfy { rhsVoltage in
                abs(lhsVoltage - rhsVoltage) <= tolerance(for: lhsVoltage, rhsVoltage, minimumTolerance: minimumTolerance)
            }
        }
    }

    static func deviceInputSupports(_ deviceInput: String, destinationSupply: String, minimumTolerance: Int = 10) -> Bool {
        let supportedRanges = parseSupportedRanges(deviceInput)
        let destinationVoltages = parseVoltages(destinationSupply)

        guard !supportedRanges.isEmpty, !destinationVoltages.isEmpty else {
            return true
        }

        return destinationVoltages.allSatisfy { destinationVoltage in
            supportedRanges.contains {
                supports(destinationVoltage, range: $0, minimumTolerance: minimumTolerance)
            }
        }
    }

    /// Whether `string` contains at least one recognizable voltage value. Callers that feed in
    /// arbitrary/user-provided text (e.g. a camera-scanned device label) should check this before
    /// trusting `isCompatible`, since `isCompatible` treats unparseable input as compatible by
    /// design (there's nothing to compare) — that default is wrong for a safety check, where
    /// "unreadable" must not be conflated with "safe". See `DeviceSafetyAssessment`.
    static func hasRecognizedValue(_ string: String) -> Bool {
        !parseVoltages(string).isEmpty
    }

    /// A flat absolute tolerance (e.g. ±20V for every comparison) is a much larger relative
    /// margin on a 100V-class device than on a 230V-class one — on a fixed single-voltage
    /// heating/motorized appliance that's a real overheating risk, not just "runs a bit hot".
    /// Scale the tolerance to the lower nominal voltage instead (±10%), with an absolute floor
    /// so very low voltages still get a workable band.
    private static func tolerance(for lhsVoltage: Int, _ rhsVoltage: Int, minimumTolerance: Int) -> Int {
        let nominalVoltage = max(min(lhsVoltage, rhsVoltage), 1)
        return max(minimumTolerance, Int((Double(nominalVoltage) * 0.1).rounded()))
    }

    private static func supports(_ voltage: Int, range: ClosedRange<Int>, minimumTolerance: Int) -> Bool {
        if range.contains(voltage) {
            return true
        }

        let nearestBound = voltage < range.lowerBound ? range.lowerBound : range.upperBound
        return abs(nearestBound - voltage) <= tolerance(
            for: nearestBound,
            voltage,
            minimumTolerance: minimumTolerance
        )
    }

    private static func parseSupportedRanges(_ string: String) -> [ClosedRange<Int>] {
        let normalized = string
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "~", with: "-")

        return normalized.split(separator: "/").flatMap { component in
            let values = parseVoltages(String(component))
            guard component.contains("-"), values.count >= 2 else {
                return values.map { $0 ... $0 }
            }

            return [min(values[0], values[1]) ... max(values[0], values[1])]
        }
    }

    private static func parseVoltages(_ string: String) -> [Int] {
        string.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}

// MARK: - PlugCompatibility

enum PlugCompatibility: Equatable {
    /// Same voltage range and plug shape — no adapter needed.
    case compatible
    /// Voltage is compatible but plug shape differs — adapter needed.
    case adapterNeeded
    /// Voltage differs significantly — a converter is required.
    case converterRequired
}

// MARK: - HomeCountryViewModelType

/// Public API for the home-country feature.
/// Individual requirements are @MainActor so concrete @MainActor classes conform naturally,
/// while the protocol itself is not @MainActor — allowing a nonisolated null default for @Entry.
protocol HomeCountryViewModelType: AnyObject {
    @MainActor var homeCountryCode: String { get }
    @MainActor var homeCountry: Country? { get }
    @MainActor var homePlugTypeIDs: Set<String> { get }
    @MainActor func setHome(code: String)
    @MainActor func clearHome()
    @MainActor func refreshHomeCountry()
    @MainActor func plugCompatibility(for plug: Plug, in country: Country) -> PlugCompatibility
}

// MARK: - NullHomeCountryViewModel

/// No-op fallback for the @Entry default value.
/// Plain class (no @MainActor, no @Observable) so its init is nonisolated — required by @Entry.
/// Never observed; replaced at the app root with a real HomeCountryViewModel.
final class NullHomeCountryViewModel: HomeCountryViewModelType {
    @MainActor var homeCountryCode: String { "" }
    @MainActor var homeCountry: Country? { nil }
    @MainActor var homePlugTypeIDs: Set<String> { [] }
    @MainActor func setHome(code: String) {}
    @MainActor func clearHome() {}
    @MainActor func refreshHomeCountry() {}
    @MainActor func plugCompatibility(for plug: Plug, in country: Country) -> PlugCompatibility { .compatible }
}

// MARK: - EnvironmentValues

extension EnvironmentValues {
    @Entry var homeCountryViewModel: any HomeCountryViewModelType = NullHomeCountryViewModel()
}

// MARK: - PreviewHomeCountryViewModel

#if DEBUG
/// Configurable in-memory stub — no SwiftData required. Use in previews and unit tests.
@Observable
@MainActor
final class PreviewHomeCountryViewModel: HomeCountryViewModelType {
    var homeCountryCode: String
    var homeCountry: Country?
    var homePlugTypeIDs: Set<String>
    var homeVoltage: String

    init(homeCountryCode: String = "", plugTypeIDs: Set<String> = [], homeVoltage: String = "") {
        self.homeCountryCode = homeCountryCode
        self.homePlugTypeIDs = plugTypeIDs
        self.homeVoltage = homeVoltage
    }

    func setHome(code: String) { homeCountryCode = code }
    func clearHome() { homeCountryCode = "" }
    func refreshHomeCountry() {}

    func plugCompatibility(for plug: Plug, in country: Country) -> PlugCompatibility {
        guard !homeCountryCode.isEmpty, country.code != homeCountryCode else {
            return .compatible
        }

        if !homeVoltage.isEmpty, !VoltageCompatibility.isCompatible(homeVoltage, country.voltage) {
            return .converterRequired
        }
        return homePlugTypeIDs.contains(plug.id) ? .compatible : .adapterNeeded
    }
}
#endif
