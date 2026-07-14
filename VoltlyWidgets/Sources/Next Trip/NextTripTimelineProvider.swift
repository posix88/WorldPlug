import Foundation
import Repository
import SwiftUI
import WidgetKit

struct NextTripEntry: TimelineEntry {
    let date: Date
    let homeCountry: CountrySnapshot?
    let country: CountrySnapshot?
    let departureDate: Date?
    let isPremium: Bool
}

struct NextTripTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTripEntry {
        NextTripEntry(
            date: .now,
            homeCountry: .preview,
            country: .preview,
            departureDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
            isPremium: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTripEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTripEntry>) -> Void) {
        let entry = loadEntry()
        completion(Timeline(entries: [entry], policy: .after(nextRefreshDate(after: entry.date))))
    }

    private func loadEntry() -> NextTripEntry {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let homeCountryCode = defaults?.string(forKey: AppGroup.homeCountryCodeKey) ?? ""
        let countryCode = defaults?.string(forKey: AppGroup.nextTripCountryCodeKey) ?? ""

        return NextTripEntry(
            date: .now,
            homeCountry: try? CountrySnapshotRepository.country(code: homeCountryCode),
            country: try? CountrySnapshotRepository.country(code: countryCode),
            departureDate: defaults?.object(forKey: AppGroup.nextTripDepartureDateKey) as? Date,
            isPremium: defaults?.bool(forKey: AppGroup.premiumAccessKey) ?? false
        )
    }

    private func nextRefreshDate(after date: Date) -> Date {
        Calendar.current.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(3600)
    }
}
