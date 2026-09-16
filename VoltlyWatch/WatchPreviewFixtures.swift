import Repository

// MARK: - WatchPreviewFixtures

@MainActor
enum WatchPreviewFixtures {
    static let italy = CountrySnapshot(
        code: "IT",
        name: "Italy",
        voltage: "230 V",
        frequency: "50 Hz",
        flagUnicode: "🇮🇹",
        plugTypeIDs: ["C", "F", "L"]
    )

    static let japan = CountrySnapshot(
        code: "JP",
        name: "Japan",
        voltage: "100 V",
        frequency: "50 / 60 Hz",
        flagUnicode: "🇯🇵",
        plugTypeIDs: ["A", "B"]
    )

    static let unitedKingdom = CountrySnapshot(
        code: "GB",
        name: "United Kingdom",
        voltage: "230 V",
        frequency: "50 Hz",
        flagUnicode: "🇬🇧",
        plugTypeIDs: ["G"]
    )

    static func catalog() -> WatchCatalogViewModel {
        WatchCatalogViewModel(countries: [italy, japan, unitedKingdom])
    }

    static func preferences(
        homeCountryCode: String = italy.code,
        savedCountryCodes: [String] = [italy.code, japan.code]
    ) -> WatchTravelPreferencesStore {
        WatchTravelPreferencesStore(
            previewPreferences: TravelPreferences(
                homeCountryCode: homeCountryCode,
                savedCountryCodes: savedCountryCodes
            )
        )
    }

    static func premium(isPremium: Bool = true) -> WatchPremiumEntitlement {
        WatchPremiumEntitlement(isPremium: isPremium)
    }
}
