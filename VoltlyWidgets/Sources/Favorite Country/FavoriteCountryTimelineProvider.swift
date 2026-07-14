import Repository
import SwiftUI
import WidgetKit

// MARK: - FavoriteCountryEntry

struct FavoriteCountryEntry: TimelineEntry {
    let date: Date
    let country: CountrySnapshot?
    let isPremium: Bool
}

// MARK: - FavoriteCountryTimelineProvider

struct FavoriteCountryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoriteCountryEntry {
        FavoriteCountryEntry(date: .now, country: .preview, isPremium: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoriteCountryEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteCountryEntry>) -> Void) {
        let entry = loadEntry()
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }

    private func loadEntry() -> FavoriteCountryEntry {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let countryCode = defaults?.string(forKey: AppGroup.favoriteCountryCodeKey) ?? ""
        let country = try? CountrySnapshotRepository.country(code: countryCode)
        let isPremium = defaults?.bool(forKey: AppGroup.premiumAccessKey) ?? false

        return FavoriteCountryEntry(date: .now, country: country, isPremium: isPremium)
    }
}
