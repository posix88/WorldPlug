import Analytics
import Foundation
import Repository
import Testing
@testable import WorldPlug

@Suite("Feature view models")
@MainActor
struct FeatureViewModelTests {
    @Test("trip check free limit presents paywall")
    func tripCheckFreeLimit() {
        let trip = TripCheck(countryCode: "JP")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(tripChecks: [trip])
        )
        let viewModel = TripCheckViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            analyticsTracker: NoopAnalyticsTracker()
        )

        viewModel.beginTripCheck()

        #expect(viewModel.isPremiumPaywallPresented)
        #expect(!viewModel.isEditorPresented)
    }

    @Test("trip check save persists and selects result")
    func tripCheckSave() {
        let store = PreviewTravelPreferencesStore()
        let viewModel = TripCheckViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
        let trip = TripCheck(countryCode: "IT")

        viewModel.save(trip)

        #expect(store.preferences.tripChecks == [trip])
        #expect(viewModel.selectedTripCheck == trip)
        #expect(viewModel.requestsReviewForSelectedTrip)
    }

    @Test("pack device view model normalizes saved name")
    func packDeviceNormalizesName() {
        let viewModel = PackDeviceEditorViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true)
        )
        viewModel.name = "  Laptop  "

        #expect(viewModel.makeDevice().name == "Laptop")
    }

    @Test("next trip view model keeps return date after departure")
    func nextTripNormalizesDates() {
        let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let viewModel = NextTripEditorViewModel(trip: nil, countries: [country])
        viewModel.returnDate = .distantPast
        viewModel.departureDateChanged()

        #expect(viewModel.returnDate == viewModel.trip.departureDate)
    }

    @Test("device label parser extracts voltage and frequency")
    func parsesDeviceLabel() {
        let values = DeviceLabelParser.values(in: "INPUT 100-240V AC 50/60Hz")

        #expect(values.voltage.contains("100-240V"))
        #expect(values.frequency.contains("50/60Hz"))
    }
}
