import Repository
import SwiftUI

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

    init(homeCountryCode: String = "", plugTypeIDs: Set<String> = []) {
        self.homeCountryCode = homeCountryCode
        self.homePlugTypeIDs = plugTypeIDs
    }

    func setHome(code: String) { homeCountryCode = code }
    func clearHome() { homeCountryCode = "" }
}
#endif
