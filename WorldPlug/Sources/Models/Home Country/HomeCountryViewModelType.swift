import Repository
import SwiftUI

// MARK: - VoltageCompatibility

enum VoltageCompatibility {
    static func isCompatible(_ lhs: String, _ rhs: String, tolerance: Int = 20) -> Bool {
        let lhsVoltages = parseVoltages(lhs)
        let rhsVoltages = parseVoltages(rhs)

        guard !lhsVoltages.isEmpty, !rhsVoltages.isEmpty else {
            return true
        }

        return lhsVoltages.contains { lhsVoltage in
            rhsVoltages.contains { rhsVoltage in
                abs(lhsVoltage - rhsVoltage) <= tolerance
            }
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
