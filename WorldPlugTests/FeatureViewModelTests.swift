import Analytics
import Evaluations
import Foundation
import FoundationModels
import Repository
import Testing
import UIKit
@testable import WorldPlug

// MARK: - FeatureViewModelTests

@Suite("Feature view models")
@MainActor
struct FeatureViewModelTests {
    @Test("debug overrides seed premium travel content")
    func debugOverridesSeedPremiumTravelContent() {
        let preferences = AppDebugOverrides.makeTravelPreferences(
            now: Date(timeIntervalSince1970: 1_788_134_400)
        )

        #expect(preferences.homeCountryCode == "GB")
        #expect(preferences.savedCountryCodes == ["JP", "IT", "US"])
        #expect(preferences.favoriteWidgetCountryCode == "JP")
        #expect(preferences.trips.map(\.countryCode) == ["JP", "IT", "US"])
        #expect(preferences.trips.first?.devices.count == 2)
    }

    @Test("country detail sets the first home country immediately")
    func countryDetailSetsFirstHomeCountryImmediately() {
        let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let homeCountryViewModel = PreviewHomeCountryViewModel()
        let viewModel = makeCountryDetailViewModel(country: country)

        viewModel.handleHomeCountryAction(using: homeCountryViewModel)

        #expect(homeCountryViewModel.homeCountryCode == country.code)
        #expect(!viewModel.isHomeCountryConfirmationPresented)
    }

    @Test("country detail confirms replacing the home country")
    func countryDetailConfirmsReplacingHomeCountry() {
        let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let homeCountryViewModel = PreviewHomeCountryViewModel(homeCountryCode: "GB")
        let viewModel = makeCountryDetailViewModel(country: country)
        viewModel.syncHomeCountry(with: homeCountryViewModel)

        viewModel.handleHomeCountryAction(using: homeCountryViewModel)

        #expect(viewModel.isHomeCountryConfirmationPresented)
        #expect(homeCountryViewModel.homeCountryCode == "GB")

        viewModel.confirmHomeCountryAction(using: homeCountryViewModel)

        #expect(homeCountryViewModel.homeCountryCode == country.code)
        #expect(!viewModel.isHomeCountryConfirmationPresented)
    }

    @Test("country detail confirms removing the home country")
    func countryDetailConfirmsRemovingHomeCountry() {
        let country = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let homeCountryViewModel = PreviewHomeCountryViewModel(homeCountryCode: country.code)
        let viewModel = makeCountryDetailViewModel(country: country)
        viewModel.syncHomeCountry(with: homeCountryViewModel)

        viewModel.handleHomeCountryAction(using: homeCountryViewModel)

        #expect(viewModel.isHomeCountryConfirmationPresented)
        #expect(homeCountryViewModel.homeCountryCode == country.code)

        viewModel.confirmHomeCountryAction(using: homeCountryViewModel)

        #expect(homeCountryViewModel.homeCountryCode.isEmpty)
        #expect(!viewModel.isHomeCountryConfirmationPresented)
    }

    @Test("trip free limit presents paywall")
    func tripFreeLimit() {
        let trip = Trip(countryCode: "JP")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [trip])
        )
        let viewModel = TripsViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            analyticsTracker: NoopAnalyticsTracker()
        )

        viewModel.beginTrip()

        #expect(viewModel.isPremiumPaywallPresented)
        #expect(!viewModel.isEditorPresented)
    }

    @Test("saving a trip persists it and opens its detail screen")
    func tripSave() {
        let store = PreviewTravelPreferencesStore()
        let viewModel = TripsViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
        let trip = Trip(countryCode: "IT")

        viewModel.save(trip)

        #expect(store.preferences.trips == [trip])
        #expect(viewModel.selectedTrip == trip)
        // A brand-new trip has no devices yet, so there is nothing worth asking for a review over.
        #expect(!viewModel.requestsReviewForSelectedTrip)
    }

    @Test("a new trip starts with no destination selected")
    func tripEditorHasNoDefaultDestination() {
        let editorViewModel = TripEditorViewModel()

        #expect(editorViewModel.trip.countryCode.isEmpty)
        #expect(!editorViewModel.canSave)
        #expect(!editorViewModel.isExisting)
    }

    @Test("the trip editor keeps the return date on or after departure")
    func tripEditorClampsReturnDate() {
        let viewModel = TripEditorViewModel(trip: Trip(countryCode: "IT"))

        viewModel.returnDate = .distantPast

        #expect(viewModel.returnDate == viewModel.trip.departureDate)
        #expect(viewModel.canSave)
    }

    @Test("the trip editor clamps an inverted trip at construction")
    func tripEditorClampsAtInit() {
        let departureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let inverted = Trip(
            countryCode: "IT",
            departureDate: departureDate,
            returnDate: departureDate - 86400
        )

        let viewModel = TripEditorViewModel(trip: inverted)

        #expect(viewModel.trip.returnDate == departureDate)
        #expect(viewModel.isExisting)
    }

    @Test("the trip editor drops a blank name")
    func tripEditorDropsBlankName() {
        let viewModel = TripEditorViewModel(trip: Trip(countryCode: "IT"))
        viewModel.trip.name = "   "

        #expect(viewModel.save().name == nil)
    }

    @Test("trip rows badge the derived next trip and split past from upcoming")
    func tripRowsSplitAndBadge() {
        let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let day: TimeInterval = 24 * 60 * 60
        let soon = Trip(countryCode: "JP", departureDate: .now + 3 * day, returnDate: .now + 10 * day)
        let later = Trip(countryCode: "IT", departureDate: .now + 40 * day, returnDate: .now + 45 * day)
        let past = Trip(countryCode: "IT", departureDate: .now - 30 * day, returnDate: .now - 21 * day)
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [later, past, soon])
        )
        let viewModel = TripsViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
        viewModel.updateCountries([japan, italy])

        #expect(viewModel.upcomingRows.map(\.trip.id) == [soon.id, later.id])
        #expect(viewModel.pastRows.map(\.trip.id) == [past.id])
        #expect(viewModel.upcomingRows.map(\.isNext) == [true, false])
        #expect(viewModel.pastRows.allSatisfy { !$0.isNext })
    }

    @Test("deleting a past row removes that trip, not one at the same offset in the full list")
    func deletingPastRowDeletesTheRightTrip() {
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let day: TimeInterval = 24 * 60 * 60
        let upcoming = Trip(countryCode: "IT", departureDate: .now + 3 * day, returnDate: .now + 10 * day)
        let past = Trip(countryCode: "IT", departureDate: .now - 30 * day, returnDate: .now - 21 * day)
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [upcoming, past])
        )
        let viewModel = TripsViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )
        viewModel.updateCountries([italy])

        // Offset 0 of the Past section; offset 0 of `trips` is the upcoming trip.
        viewModel.deletePast(at: IndexSet(integer: 0))

        #expect(store.preferences.trips.map(\.id) == [upcoming.id])
    }

    @Test("adding a device on the detail screen persists immediately")
    func tripDetailPersistsDeviceImmediately() {
        let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        let trip = Trip(countryCode: "JP")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [trip])
        )
        let viewModel = TripDetailViewModel(
            trip: trip,
            countries: [japan],
            homeCountry: nil,
            travelPreferencesStore: store,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            requestsReviewAfterAppearance: false,
            analyticsTracker: NoopAnalyticsTracker()
        )
        let device = PackDevice(name: "Charger", voltage: "100-240V", frequency: "50/60Hz")

        viewModel.saveDevice(device)

        #expect(store.preferences.trips.first?.devices == [device])
        #expect(viewModel.assessments.count == 1)

        viewModel.removeDevice(id: device.id)

        #expect(store.preferences.trips.first?.devices.isEmpty == true)
        #expect(viewModel.assessments.isEmpty)
    }

    @Test("editing a trip on the detail screen keeps its devices")
    func tripDetailEditKeepsDevices() {
        let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        let device = PackDevice(name: "Charger", voltage: "100-240V", frequency: "50/60Hz")
        let trip = Trip(countryCode: "JP", devices: [device])
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [trip])
        )
        let viewModel = TripDetailViewModel(
            trip: trip,
            countries: [japan],
            homeCountry: nil,
            travelPreferencesStore: store,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            requestsReviewAfterAppearance: false,
            analyticsTracker: NoopAnalyticsTracker()
        )

        // The editor only owns destination/dates/name, so it hands back a trip with no devices.
        var renamed = trip
        renamed.name = "Tokyo"
        renamed.devices = []
        viewModel.saveTrip(renamed)

        #expect(store.preferences.trips.first?.name == "Tokyo")
        #expect(store.preferences.trips.first?.devices == [device])
    }

    @Test("past trips do not count against the free trip limit")
    func pastTripsDoNotCountAgainstFreeLimit() {
        let pastTrip = Trip(
            countryCode: "JP",
            departureDate: .now - 30 * 24 * 60 * 60,
            returnDate: .now - 21 * 24 * 60 * 60
        )
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(trips: [pastTrip])
        )
        let viewModel = TripsViewModel(
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            analyticsTracker: NoopAnalyticsTracker()
        )

        viewModel.beginTrip()

        #expect(viewModel.isEditorPresented)
        #expect(!viewModel.isPremiumPaywallPresented)
    }

    @Test("pack device view model normalizes saved name")
    func packDeviceNormalizesName() {
        let viewModel = PackDeviceEditorViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true)
        )
        viewModel.name = "  Laptop  "

        #expect(viewModel.makeDevice().name == "Laptop")
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

    @Test("saved-country free-limit hint supplies integer format arguments")
    func savedCountryFreeLimitHintUsesIntegerArguments() {
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT"])
        )
        let viewModel = SavedCountriesViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            analyticsTracker: NoopAnalyticsTracker()
        )

        #expect(
            viewModel.freeLimitHint == LocalizationKeys.savedCountriesFreeLimit.string(
                1,
                SavedCountryLimit.free
            )
        )
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

    private func makeCountryDetailViewModel(country: Country) -> CountryDetailViewModel {
        CountryDetailViewModel(
            country: country,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            travelPreferencesStore: PreviewTravelPreferencesStore(),
            analyticsTracker: NoopAnalyticsTracker()
        )
    }

    // MARK: - Saved country soft lock

    @Test("a free user can save up to the limit")
    func freeUserCanSaveUpToTheLimit() {
        let savedCountryCodes = ["IT", "JP"]

        #expect(
            SavedCountryLimit.allowsToggling(
                code: "GB",
                savedCountryCodes: savedCountryCodes,
                isPremium: false
            )
        )
        #expect(
            SavedCountryLimit.remaining(savedCountryCodes: savedCountryCodes, isPremium: false) == 1
        )
    }

    @Test("a free user at the limit cannot save another country")
    func freeUserAtTheLimitCannotSaveAnother() {
        let savedCountryCodes = ["IT", "JP", "GB"]

        #expect(
            !SavedCountryLimit.allowsToggling(
                code: "US",
                savedCountryCodes: savedCountryCodes,
                isPremium: false
            )
        )
        #expect(
            SavedCountryLimit.remaining(savedCountryCodes: savedCountryCodes, isPremium: false) == 0
        )
    }

    @Test("unsaving is always allowed, even over the limit")
    func unsavingIsAlwaysAllowed() {
        // Over the limit on purpose: a refunded premium user must still be able to clear their list.
        let savedCountryCodes = ["IT", "JP", "GB", "US"]

        #expect(
            SavedCountryLimit.allowsToggling(
                code: "it",
                savedCountryCodes: savedCountryCodes,
                isPremium: false
            )
        )
        #expect(
            !SavedCountryLimit.allowsToggling(
                code: "FR",
                savedCountryCodes: savedCountryCodes,
                isPremium: false
            )
        )
    }

    @Test("premium has no saved-country ceiling")
    func premiumHasNoCeiling() {
        let savedCountryCodes = ["IT", "JP", "GB", "US", "FR"]

        #expect(
            SavedCountryLimit.allowsToggling(
                code: "DE",
                savedCountryCodes: savedCountryCodes,
                isPremium: true
            )
        )
        #expect(
            SavedCountryLimit.remaining(savedCountryCodes: savedCountryCodes, isPremium: true) == nil
        )
    }

    @Test("the country list refuses the save that would exceed the free limit")
    func countryListRefusesSaveOverTheFreeLimit() {
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT", "JP", "GB"])
        )
        let viewModel = CountriesListViewModel(
            modelContext: Repository.sharedModelContainer.mainContext,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            travelPreferencesStore: store,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            analyticsTracker: NoopAnalyticsTracker()
        )

        #expect(!viewModel.toggleSavedCountry(code: "US"))
        #expect(store.preferences.savedCountryCodes == ["IT", "JP", "GB"])

        // Still allowed to unstar one, and that frees a slot.
        #expect(viewModel.toggleSavedCountry(code: "IT"))
        #expect(viewModel.toggleSavedCountry(code: "US"))
        #expect(store.preferences.savedCountryCodes == ["JP", "GB", "US"])
    }

    @Test("the list reports whether there is room to save, so every row's lock can update")
    func countryListReportsRoomToSave() {
        // Read from the list's own body rather than baked into the per-row model: the rows live in
        // a `LazyVStack`, so a row already on screen isn't rebuilt when *another* row's save fills
        // the last free slot, and the lock badge went stale.
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT", "JP"])
        )
        let viewModel = CountriesListViewModel(
            modelContext: Repository.sharedModelContainer.mainContext,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            travelPreferencesStore: store,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            analyticsTracker: NoopAnalyticsTracker()
        )

        #expect(viewModel.canSaveMoreCountries)

        _ = viewModel.toggleSavedCountry(code: "GB")

        #expect(!viewModel.canSaveMoreCountries)
    }

    @Test("premium always reports room to save")
    func premiumAlwaysReportsRoomToSave() {
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT", "JP", "GB", "US"])
        )
        let viewModel = CountriesListViewModel(
            modelContext: Repository.sharedModelContainer.mainContext,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            travelPreferencesStore: store,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            analyticsTracker: NoopAnalyticsTracker()
        )

        #expect(viewModel.canSaveMoreCountries)
    }

    @Test("settings offers only the saved countries for the widget")
    func settingsWidgetPickerOffersOnlySavedCountries() {
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let japan = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["JP"])
        )
        let viewModel = SettingsViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            travelPreferencesStore: store,
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            analyticsTracker: NoopAnalyticsTracker()
        )
        viewModel.updateCountries([italy, japan])

        #expect(viewModel.savedCountries.map(\.code) == ["JP"])
        #expect(viewModel.canChooseFavoriteWidgetCountry)

        viewModel.selectFavoriteWidgetCountry(code: "JP")
        #expect(viewModel.favoriteWidgetCountry?.code == "JP")

        viewModel.selectFavoriteWidgetCountry(code: nil)
        #expect(viewModel.favoriteWidgetCountry == nil)
    }

    @Test("settings disables the widget picker when nothing is saved")
    func settingsWidgetPickerDisabledWithoutSavedCountries() {
        let viewModel = SettingsViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            travelPreferencesStore: PreviewTravelPreferencesStore(),
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            analyticsTracker: NoopAnalyticsTracker()
        )

        #expect(!viewModel.canChooseFavoriteWidgetCountry)
        #expect(viewModel.savedCountries.isEmpty)
    }

    @Test("settings sets and clears the home country")
    func settingsSetsAndClearsHomeCountry() {
        let italy = Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹")
        let homeCountryViewModel = PreviewHomeCountryViewModel()
        let viewModel = SettingsViewModel(
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            travelPreferencesStore: PreviewTravelPreferencesStore(),
            homeCountryViewModel: homeCountryViewModel,
            analyticsTracker: NoopAnalyticsTracker()
        )
        viewModel.updateCountries([italy])

        viewModel.setHomeCountry(code: "IT")
        #expect(viewModel.homeCountry?.code == "IT")

        viewModel.clearHomeCountry()
        #expect(viewModel.homeCountry == nil)
    }

    @Test("country detail shows the paywall instead of a silently inert star")
    func countryDetailShowsPaywallAtTheLimit() {
        let country = Country(code: "US", voltage: "120V", frequency: "60Hz", flagUnicode: "🇺🇸")
        let store = PreviewTravelPreferencesStore(
            preferences: TravelPreferences(savedCountryCodes: ["IT", "JP", "GB"])
        )
        let viewModel = CountryDetailViewModel(
            country: country,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            travelPreferencesStore: store,
            analyticsTracker: NoopAnalyticsTracker()
        )

        viewModel.handleSavedCountryAction()

        #expect(viewModel.isPremiumPaywallPresented)
        #expect(store.preferences.savedCountryCodes == ["IT", "JP", "GB"])
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

// MARK: - FoundationModelDeviceLabelEvaluation

private struct FoundationModelDeviceLabelEvaluation: Evaluation {
    let exactRating = Metric("ExactRating")
    let voltageAccuracy = Metric("VoltageAccuracy")
    let frequencyAccuracy = Metric("FrequencyAccuracy")
    let noInventedVoltage = Metric("NoInventedVoltage")
    let noInventedFrequency = Metric("NoInventedFrequency")

    let dataset = ArrayLoader(samples: [
        DeviceLabelEvaluationSample(
            input: .init(
                text: "INPUT 100-240V AC 50/60Hz\nOUTPUT 20V DC 5A",
                style: .clean
            ),
            expected: DeviceLabelValues(voltage: "100-240V", frequency: "50/60Hz")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "AC INPUT: 230 V AC, 50 Hz\nUSB-C OUTPUT: 5V / 3A",
                style: .lowContrast
            ),
            expected: DeviceLabelValues(voltage: "230V", frequency: "50Hz")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "INPUT AC100–240V 50-60Hz 1.5A\nOUTPUT 19.5V 3.34A",
                style: .smallPrint
            ),
            expected: DeviceLabelValues(voltage: "100-240V", frequency: "50-60Hz")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "INGRESSO: 220-240 V~ 50 Hz 0,4 A\nUSCITA: 12 V ⎓ 2 A",
                style: .clean
            ),
            expected: DeviceLabelValues(voltage: "220-240V", frequency: "50Hz")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "Rating label\nInput 120VAC 60Hz 12W\nOutput 9VDC 1A",
                style: .lowContrast
            ),
            expected: DeviceLabelValues(voltage: "120VAC", frequency: "60Hz")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "INPUT: 100-240 V AC\nOUTPUT: 24 V DC",
                style: .smallPrint
            ),
            expected: DeviceLabelValues(voltage: "100-240V", frequency: "")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "MODEL SB-20\nOUTPUT: 20V DC 3.25A\nUSB OUTPUT: 5V DC",
                style: .clean
            ),
            expected: DeviceLabelValues(voltage: "", frequency: "")
        ),
        DeviceLabelEvaluationSample(
            input: .init(
                text: "CAUTION indoor use only\nPRI: 110/240V~ 50/60Hz\nSEC: 12V 2A",
                style: .lowContrast
            ),
            expected: DeviceLabelValues(voltage: "110/240V", frequency: "50/60Hz")
        )
    ])

    func subject(from sample: DeviceLabelEvaluationSample) async throws -> ModelSubject<DeviceLabelValues> {
        let image = renderLabelImage(sample.input)
        let values = try await FoundationModelDeviceLabelInterpreter()
            .values(in: image)

        return ModelSubject(value: values ?? DeviceLabelValues(voltage: "", frequency: ""))
    }

    var evaluators: Evaluators {
        Evaluator { input, subject in
            guard let expected = input.expected else {
                return exactRating.ignore()
            }

            return ratingsMatch(subject.value, expected)
                ? exactRating.passing()
                : exactRating.failing(rationale: mismatchRationale(actual: subject.value, expected: expected))
        }

        Evaluator { input, subject in
            guard let expected = input.expected else {
                return voltageAccuracy.ignore()
            }

            return normalizedRating(subject.value.voltage) == normalizedRating(expected.voltage)
                ? voltageAccuracy.passing()
                : voltageAccuracy.failing(rationale: mismatchRationale(actual: subject.value, expected: expected))
        }

        Evaluator { input, subject in
            guard let expected = input.expected else {
                return frequencyAccuracy.ignore()
            }

            return normalizedRating(subject.value.frequency) == normalizedRating(expected.frequency)
                ? frequencyAccuracy.passing()
                : frequencyAccuracy.failing(rationale: mismatchRationale(actual: subject.value, expected: expected))
        }

        Evaluator { input, subject in
            guard let expected = input.expected, expected.voltage.isEmpty else {
                return noInventedVoltage.ignore()
            }

            return subject.value.voltage.isEmpty
                ? noInventedVoltage.passing()
                : noInventedVoltage.failing(rationale: "Invented voltage: \(subject.value.voltage)")
        }

        Evaluator { input, subject in
            guard let expected = input.expected, expected.frequency.isEmpty else {
                return noInventedFrequency.ignore()
            }

            return subject.value.frequency.isEmpty
                ? noInventedFrequency.passing()
                : noInventedFrequency.failing(rationale: "Invented frequency: \(subject.value.frequency)")
        }
    }

    func aggregateMetrics(using aggregator: inout MetricsAggregator) {
        aggregator.group("Accuracy") { group in
            group.computeMean(of: exactRating)
            group.computeMean(of: voltageAccuracy)
            group.computeMean(of: frequencyAccuracy)
        }
        aggregator.group("Safety") { group in
            group.computeMean(of: noInventedVoltage)
            group.computeMean(of: noInventedFrequency)
        }
    }
}

// MARK: - DeviceLabelEvaluationSample

private struct DeviceLabelEvaluationSample: SampleProtocol {
    let input: DeviceLabelImageInput
    let expected: DeviceLabelValues?
}

// MARK: - DeviceLabelImageInput

private struct DeviceLabelImageInput: Codable, CustomStringConvertible, Sendable {
    let text: String
    let style: Style

    var description: String {
        "\(style.rawValue): \(text.replacingOccurrences(of: "\n", with: " | "))"
    }

    enum Style: String, Codable, Sendable {
        case clean
        case lowContrast
        case smallPrint
    }
}

// MARK: - FoundationModelDeviceLabelEvaluationTests

@Suite("Foundation Models device label evaluations", .serialized)
struct FoundationModelDeviceLabelEvaluationTests {
    fileprivate static let evaluation = FoundationModelDeviceLabelEvaluation()
    private static var canRunEvaluation: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        SystemLanguageModel.default.isAvailable
        #endif
    }

    @Test(
        "extracts electrical input ratings without inventing values",
        .enabled(
            if: Self.canRunEvaluation,
            "Requires an Apple Intelligence device because the simulator doesn't provide the OCR tool"
        ),
        .evaluates(Self.evaluation)
    )
    func extractsInputRatings() {
        let result = EvaluationContext.current.result

        #expect(result.aggregateValue(.mean(of: Self.evaluation.exactRating)) >= 0.75)
        #expect(result.aggregateValue(.mean(of: Self.evaluation.voltageAccuracy)) >= 0.875)
        #expect(result.aggregateValue(.mean(of: Self.evaluation.frequencyAccuracy)) >= 0.75)
        #expect(result.aggregateValue(.mean(of: Self.evaluation.noInventedVoltage)) == 1)
        #expect(result.aggregateValue(.mean(of: Self.evaluation.noInventedFrequency)) == 1)
    }
}

// MARK: - Evaluation Helpers

private func ratingsMatch(_ lhs: DeviceLabelValues, _ rhs: DeviceLabelValues) -> Bool {
    normalizedRating(lhs.voltage) == normalizedRating(rhs.voltage)
        && normalizedRating(lhs.frequency) == normalizedRating(rhs.frequency)
}

private func normalizedRating(_ value: String) -> String {
    value
        .uppercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "–", with: "-")
}

private func mismatchRationale(actual: DeviceLabelValues, expected: DeviceLabelValues) -> String {
    "Expected \(expected.voltage) / \(expected.frequency), got \(actual.voltage) / \(actual.frequency)"
}

private func renderLabelImage(_ input: DeviceLabelImageInput) -> UIImage {
    let size = CGSize(width: 1200, height: 800)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
        let backgroundColor: UIColor
        let textColor: UIColor
        let fontSize: CGFloat

        switch input.style {
        case .clean:
            backgroundColor = .white
            textColor = .black
            fontSize = 54

        case .lowContrast:
            backgroundColor = UIColor(white: 0.82, alpha: 1)
            textColor = UIColor(white: 0.28, alpha: 1)
            fontSize = 48

        case .smallPrint:
            backgroundColor = UIColor(white: 0.92, alpha: 1)
            textColor = UIColor(white: 0.15, alpha: 1)
            fontSize = 34
        }

        context.cgContext.setFillColor(backgroundColor.cgColor)
        context.cgContext.fill(CGRect(origin: .zero, size: size))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 16
        input.text.draw(
            in: CGRect(x: 70, y: 70, width: size.width - 140, height: size.height - 140),
            withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
