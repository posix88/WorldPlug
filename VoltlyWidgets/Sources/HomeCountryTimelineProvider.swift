import Repository
import SwiftUI
import WidgetKit

// MARK: - HomeCountryTimelineProvider

struct HomeCountryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeCountryEntry {
        HomeCountryEntry(date: .now, country: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeCountryEntry) -> Void) {
        completion(HomeCountryEntry(date: .now, country: loadCountry()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeCountryEntry>) -> Void) {
        let entry = HomeCountryEntry(date: .now, country: loadCountry())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }

    private func loadCountry() -> CountrySnapshot? {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let code = defaults?.string(forKey: AppGroup.homeCountryCodeKey) ?? ""
        return try? CountrySnapshotRepository.country(code: code)
    }
}
