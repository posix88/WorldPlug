import Analytics
import Foundation
import Repository
import Testing
import UIKit
@testable import WorldPlug

// MARK: - FeatureViewModelTests

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

    @Test("new pack check preselects the next trip country")
    func tripCheckPreselectsNextTripCountry() {
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(
                nextTrip: NextTrip(
                    countryCode: japan.code,
                    departureDate: .now,
                    returnDate: .now
                )
            )
        )
        let tripCheckViewModel = TripCheckViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
        tripCheckViewModel.updateCountries([italy, japan])

        let editorViewModel = TripCheckEditorViewModel(
            countries: [italy, japan],
            initialCountryCode: tripCheckViewModel.initialCountryCode,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true)
        )

        #expect(editorViewModel.tripCheck.countryCode == japan.code)
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

    @Test("saved countries removal does not toggle a removed country back on")
    func savedCountriesRemovalIsIdempotent() {
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT"])
        )
        let viewModel = SavedCountriesViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            analyticsTracker: NoopAnalyticsTracker()
        )

        viewModel.removeSavedCountry(code: "IT")
        viewModel.removeSavedCountry(code: "IT")

        #expect(store.preferences.savedCountryCodes.isEmpty)
    }

    @Test("device label parser extracts voltage and frequency")
    func parsesDeviceLabel() {
        let values = DeviceLabelParser.values(in: "INPUT 100-240V AC 50/60Hz")

        #expect(values.voltage.contains("100-240V"))
        #expect(values.frequency.contains("50/60Hz"))
    }

    @Test("device label scanner uses smart interpretation when available")
    func deviceLabelScannerUsesSmartInterpretation() async {
        let expectedValues = DeviceLabelValues(voltage: "100-240V", frequency: "50/60Hz")
        let viewModel = DeviceLabelScannerViewModel(
            interpreter: DeviceLabelInterpreterStub(result: expectedValues)
        )

        let values = await viewModel.analyze(image: UIImage(), fallbackText: "")

        #expect(values == expectedValues)
        #expect(viewModel.state == .idle)
    }

    @Test("device label scanner falls back to recognized text after model failure")
    func deviceLabelScannerFallsBackAfterModelFailure() async {
        let viewModel = DeviceLabelScannerViewModel(
            interpreter: DeviceLabelInterpreterStub(shouldThrow: true)
        )

        let values = await viewModel.analyze(
            image: UIImage(),
            fallbackText: "INPUT 110-240V AC 50/60Hz"
        )

        #expect(values?.voltage.contains("110-240V") == true)
        #expect(values?.frequency.contains("50/60Hz") == true)
        #expect(viewModel.state == .idle)
    }

    @Test("device label scanner reports when no voltage is found")
    func deviceLabelScannerReportsNoValues() async {
        let viewModel = DeviceLabelScannerViewModel(
            interpreter: DeviceLabelInterpreterStub(isAvailable: false)
        )

        let values = await viewModel.analyze(image: nil, fallbackText: "MODEL ABC")

        #expect(values == nil)
        #expect(viewModel.state == .noValuesFound)
    }
}

// MARK: - DeviceLabelInterpreterStub

private struct DeviceLabelInterpreterStub: DeviceLabelInterpreting {
    let isAvailable: Bool
    let result: DeviceLabelValues?
    let shouldThrow: Bool

    init(
        isAvailable: Bool = true,
        result: DeviceLabelValues? = nil,
        shouldThrow: Bool = false
    ) {
        self.isAvailable = isAvailable
        self.result = result
        self.shouldThrow = shouldThrow
    }

    func values(in image: UIImage) async throws -> DeviceLabelValues? {
        if shouldThrow {
            throw DeviceLabelInterpreterStubError.interpretationFailed
        }
        return result
    }
}

// MARK: - DeviceLabelInterpreterStubError

private enum DeviceLabelInterpreterStubError: Error {
    case interpretationFailed
}
