import Foundation
import Repository

// MARK: - WatchAppDebugOverrides

/// Deterministic content for local App Store screenshot capture.
/// This is compiled out of release builds and is enabled only with a launch argument.
enum WatchAppDebugOverrides {
    enum ScreenshotScreen {
        case saved
        case homeCountry
        case countries
        case italy
    }

    #if DEBUG
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TEST_SEED_DATA")
            || ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT")
    }
    #else
    static let isEnabled = false
    #endif

    static var travelPreferences: TravelPreferences? {
        guard isEnabled else {
            return nil
        }

        return TravelPreferences(
            homeCountryCode: "GB",
            savedCountryCodes: ["JP", "IT", "US"]
        )
    }

    static var screenshotScreen: ScreenshotScreen? {
        guard isEnabled else {
            return nil
        }

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("UI_TEST_SCREEN_SAVED") {
            return .saved
        }
        if arguments.contains("UI_TEST_SCREEN_HOME_COUNTRY") {
            return .homeCountry
        }
        if arguments.contains("UI_TEST_SCREEN_COUNTRIES") {
            return .countries
        }
        if arguments.contains("UI_TEST_SCREEN_ITALY") {
            return .italy
        }
        return nil
    }
}
