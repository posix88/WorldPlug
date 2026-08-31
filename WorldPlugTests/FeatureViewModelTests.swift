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

    private func makeCountryDetailViewModel(country: Country) -> CountryDetailViewModel {
        CountryDetailViewModel(
            country: country,
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            travelPreferencesStore: PreviewTravelPreferencesStore(),
            analyticsTracker: NoopAnalyticsTracker()
        )
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
