import Foundation

// MARK: - AppDebugOverrides

enum AppDebugOverrides {
    #if DEBUG
    /// Set to `true` to launch the app locally with the same deterministic data used for
    /// App Store screenshots. Fastlane enables this automatically through a launch argument.
    static let isManuallyEnabled = false

    static var isEnabled: Bool {
        isManuallyEnabled
            || ProcessInfo.processInfo.arguments.contains("UI_TEST_SEED_DATA")
            || ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT")
    }
    #else
    static let isEnabled = false
    #endif

    static var homeCountryCode: String? {
        isEnabled ? "GB" : nil
    }

    static var premiumStatus: Bool? {
        isEnabled ? true : nil
    }

    static var travelPreferences: TravelPreferences? {
        guard isEnabled else {
            return nil
        }

        return makeTravelPreferences()
    }

    static func makeTravelPreferences(now: Date = .now) -> TravelPreferences {
        let calendar = Calendar(identifier: .gregorian)
        let departureDate = calendar.date(byAdding: .day, value: 21, to: now) ?? now
        let returnDate = calendar.date(byAdding: .day, value: 29, to: now) ?? departureDate

        return TravelPreferences(
            homeCountryCode: "GB",
            savedCountryCodes: ["JP", "IT", "US"],
            favoriteWidgetCountryCode: "JP",
            trips: [
                Trip(
                    countryCode: "JP",
                    departureDate: departureDate,
                    returnDate: returnDate,
                    devices: [
                        PackDevice(
                            name: String(localized: LocalizationKeys.tripCheckDevicePhone),
                            symbolName: "iphone",
                            voltage: "100-240V",
                            frequency: "50/60Hz"
                        ),
                        PackDevice(
                            name: String(localized: LocalizationKeys.tripCheckDeviceHairDryer),
                            symbolName: "wind",
                            voltage: "220-240V",
                            frequency: "50Hz"
                        )
                    ]
                ),
                Trip(
                    countryCode: "IT",
                    departureDate: calendar.date(byAdding: .day, value: 45, to: now) ?? departureDate,
                    returnDate: calendar.date(byAdding: .day, value: 50, to: now) ?? returnDate,
                    devices: [
                        PackDevice(
                            name: String(localized: LocalizationKeys.tripCheckDeviceLaptop),
                            symbolName: "laptopcomputer",
                            voltage: "100-240V",
                            frequency: "50/60Hz"
                        )
                    ]
                ),
                // Already over, so the list's dimmed "past" treatment and the
                // "past trips don't count against the free limit" rule are both exercisable.
                Trip(
                    countryCode: "US",
                    departureDate: calendar.date(byAdding: .day, value: -30, to: now) ?? now,
                    returnDate: calendar.date(byAdding: .day, value: -21, to: now) ?? now,
                    devices: [
                        PackDevice(
                            name: String(localized: LocalizationKeys.tripCheckDeviceCamera),
                            symbolName: "camera",
                            voltage: "100-240V",
                            frequency: "50/60Hz"
                        )
                    ]
                )
            ]
        )
    }
}
