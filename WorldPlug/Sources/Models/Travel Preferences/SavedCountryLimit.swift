import Foundation

// MARK: - SavedCountryLimit

/// The free tier's ceiling on saved countries.
///
/// This lives here, shared, rather than in either screen, because saving happens from **two**
/// places — the country list's swipe action and the country-detail star — and the two must agree
/// on when the paywall appears. Enforcing it at the point of saving (rather than locking the Saved
/// tab wholesale, which is what the app used to do) is the point: a free user gets a working
/// feature with a limit, not a screen they can't open.
enum SavedCountryLimit {
    /// Enough to feel useful, few enough to bite on a real trip.
    static let free = 3

    /// Whether toggling `code` is allowed right now.
    ///
    /// **Un**saving is always allowed, premium or not — otherwise a free user who somehow ended up
    /// over the limit (bought premium, saved ten countries, refunded) would be stuck unable to
    /// remove any of them.
    static func allowsToggling(
        code: String,
        preferences: TravelPreferences,
        isPremium: Bool
    ) -> Bool {
        let code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        return isPremium
            || preferences.savedCountryCodes.contains(code)
            || preferences.savedCountryCodes.count < free
    }

    /// How many saves a free user has left, for a "2 of 3 saved" style hint. `nil` for premium,
    /// which has no ceiling to report.
    static func remaining(preferences: TravelPreferences, isPremium: Bool) -> Int? {
        guard !isPremium else {
            return nil
        }

        return max(0, free - preferences.savedCountryCodes.count)
    }
}
