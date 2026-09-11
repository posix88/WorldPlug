import Analytics
import AppIntents
import Repository
import StoreKit
import SwiftUI

// MARK: - TripDetailView

/// A single trip: where and when, the devices packed for it, and each device's verdict. This is
/// where devices are added — the trip itself is created first, in `TripEditorView`.
struct TripDetailView: View {
    @Environment(\.locale) private var locale
    @Environment(\.requestReview) private var requestReview
    @State private var viewModel: TripDetailViewModel
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let countries: [Country]

    init(
        trip: Trip,
        countries: [Country],
        homeCountry: Country?,
        travelPreferencesStore: any TravelPreferencesStoring,
        premiumEntitlement: any PremiumEntitlementProviding,
        requestsReviewAfterAppearance: Bool,
        analyticsTracker: any AnalyticsTracker
    ) {
        _viewModel = State(
            initialValue: TripDetailViewModel(
                trip: trip,
                countries: countries,
                homeCountry: homeCountry,
                travelPreferencesStore: travelPreferencesStore,
                premiumEntitlement: premiumEntitlement,
                requestsReviewAfterAppearance: requestsReviewAfterAppearance,
                analyticsTracker: analyticsTracker
            )
        )
        self.premiumEntitlement = premiumEntitlement
        self.countries = countries
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        content
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .appEntityIdentifier(
                EntityIdentifier(for: TripEntity.self, identifier: viewModel.trip.id)
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.editTrip) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityIdentifier("trip.detail.edit")
                    .accessibilityLabel(LocalizationKeys.tripDetailEdit.localized)
                }
            }
            .sheet(isPresented: $viewModel.isDeviceEditorPresented) {
                PackDeviceEditorSheet(
                    path: $viewModel.deviceEditorPath,
                    scannerValues: $viewModel.scannedValues,
                    device: viewModel.editingDevice,
                    premiumEntitlement: premiumEntitlement,
                    onSave: viewModel.saveDevice,
                    onScanRequested: viewModel.requestLabelScan
                )
            }
            .sheet(isPresented: $viewModel.isTripEditorPresented) {
                TripEditorView(
                    trip: viewModel.trip,
                    countries: countries,
                    onSave: viewModel.saveTrip
                )
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .trips)
            }
            .sheet(isPresented: $viewModel.isDisclaimerPresented) {
                TripDisclaimerView()
            }
            .onAppear {
                viewModel.screenAppeared(requestReview: { requestReview() })
            }
            .tint(.voltTint)
    }

    private var navigationTitle: String {
        guard let destination = viewModel.destination else {
            return viewModel.trip.name ?? viewModel.trip.countryCode
        }

        return viewModel.trip.name ?? destination.localizedName(in: locale)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.destination == nil {
            ContentUnavailableView(
                LocalizationKeys.tripCheckUnavailable.localized,
                systemImage: "exclamationmark.triangle"
            )
        } else {
            List {
                headerSection
                devicesSection
            }
            .scrollContentBackground(.hidden)
            .background { AppMeshBackground() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                disclaimerButton
            }
            .scrollBounceBehavior(.basedOnSize)
            .accessibilityIdentifier("trip.detail.list")
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        if let destination = viewModel.destination {
            Section {
                VStack(alignment: .leading, spacing: .lg) {
                    Text("\(destination.flagUnicode) \(destination.localizedName(in: locale))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(TripDateFormat.range(from: viewModel.trip, locale: locale))
                        .font(.footnote)
                        .foregroundStyle(.textLight)

                    HStack(spacing: .md) {
                        TripMetricTile(
                            icon: .boltCircleFill,
                            title: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                            value: destination.voltage,
                            color: .voltTint
                        )

                        TripMetricTile(
                            icon: .waveform,
                            title: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                            value: destination.frequency,
                            color: .frequencyTint
                        )
                    }
                }
                .appEntityIdentifier(
                    EntityIdentifier(for: CountryEntity.self, identifier: destination.code)
                )
            }
        }
    }

    @ViewBuilder
    private var devicesSection: some View {
        Section(LocalizationKeys.tripCheckSafetySection.localized) {
            ForEach(viewModel.assessments) { assessment in
                assessmentRow(assessment)
            }
            if viewModel.trip.devices.isEmpty {
                devicesEmptyState
            }
        }

        Section {
            addDeviceButton
        }
    }

    private var devicesEmptyState: some View {
        HStack(alignment: .top, spacing: .lg) {
            SFSymbols.powerPlug.image
                .font(.title3)
                .foregroundStyle(.textLighter)
                .frame(width: DesignTokens.Size.smallIcon)

            VStack(alignment: .leading, spacing: .xs) {
                Text(LocalizationKeys.tripDetailDevicesEmptyTitle.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textRegular)

                Text(LocalizationKeys.tripDetailDevicesEmptyDescription.localized)
                    .font(.caption)
                    .foregroundStyle(.textLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .listRowSeparator(.hidden)
    }

    private func assessmentRow(_ assessment: DeviceSafetyAssessment) -> some View {
        let color = Self.statusColor(assessment.status)
        
        return Button { viewModel.editDevice(assessment.device)  } label: {
            Label {
                VStack(alignment: .leading, spacing: .xs) {
                    HStack(spacing: .sm) {
                        Text(assessment.device.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.textRegular)
                        
                        Spacer(minLength: .xs)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    
                    deviceRatings(assessment.device)
                    
                    Text(assessment.status.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                    Text(assessment.message)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: assessment.device.symbolName)
                    .foregroundStyle(color)
            }
            .contentShape(Rectangle())
        }
        .appEntityIdentifier(
            EntityIdentifier(for: PackDeviceEntity.self, identifier: assessment.device.id)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.removeDevice(id: assessment.device.id)
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel(LocalizationKeys.tripCheckRemoveDevice.localized)
            
            Button {
                viewModel.editDevice(assessment.device)
            } label: {
                Image(systemName: "pencil")
            }
            .accessibilityIdentifier("trip.detail.edit")
            .accessibilityLabel(LocalizationKeys.tripDetailEdit.localized)
        }
    }

    /// The device's own ratings, in the same chips the country cards use for a country's. Without
    /// them the row asserted a verdict while hiding the two numbers it was derived from, so a bad
    /// scan was invisible. A device with no frequency recorded shows only the voltage chip —
    /// `PackDevice.frequency` defaults to "" and a scanned device can genuinely lack it.
    @ViewBuilder
    private func deviceRatings(_ device: PackDevice) -> some View {
        HStack(spacing: .sm) {
            if !device.voltage.isEmpty {
                ElectricalSpecificationPill(
                    icon: .boltCircleFill,
                    label: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                    value: device.voltage,
                    color: .voltTint
                )
            }

            if !device.frequency.isEmpty {
                ElectricalSpecificationPill(
                    icon: .waveform,
                    label: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                    value: device.frequency,
                    color: .frequencyTint
                )
            }
        }
    }

    private var addDeviceButton: some View {
        Button(action: viewModel.addDevice) {
            Label(LocalizationKeys.tripCheckAddDevice.localized, systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.voltTint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("trip.detail.addDevice")
    }

    private var disclaimerButton: some View {
        Button {
            viewModel.isDisclaimerPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationKeys.tripCheckDisclaimerTitle.localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.statusCheck)

                    Text(LocalizationKeys.tripCheckDisclaimerSummary.localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .foregroundStyle(.voltTint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.interactive())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding([.horizontal, .bottom])
    }

    private static func statusColor(_ status: DeviceSafetyStatus) -> Color {
        switch status {
        case .ready: .statusReady
        case .adapterNeeded: .statusAdapter
        case .homeCountryRequired: .statusCheck
        case .checkLabel: .statusCheck
        case .unsafe: .statusUnsafe
        }
    }
}

// MARK: - TripMetricTile

private struct TripMetricTile: View {
    let icon: SFSymbols
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            HStack(spacing: .sm) {
                icon.image
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.textLight)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.textRegular)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.lg)
        .background(.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - PackDeviceEditorSheet

private struct PackDeviceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [PackDeviceEditorRoute]
    @Binding var scannerValues: DeviceLabelValues?
    /// `nil` when adding a device, set when editing one.
    let device: PackDevice?
    let premiumEntitlement: any PremiumEntitlementProviding
    let onSave: (PackDevice) -> Void
    let onScanRequested: () -> Void

    var body: some View {
        NavigationStack(path: $path) {
            PackDeviceEditorView(
                device: device,
                scannerValues: $scannerValues,
                premiumEntitlement: premiumEntitlement,
                onSave: onSave,
                onScanRequested: onScanRequested
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(LocalizationKeys.tripCheckCancel.localized)
                }
            }
            .navigationDestination(for: PackDeviceEditorRoute.self) { route in
                switch route {
                case .labelScanner:
                    DeviceLabelScannerView(
                        interpreter: FoundationModelDeviceLabelInterpreter(),
                        onRecognized: { scannerValues = $0 }
                    )
                }
            }
        }
    }
}

// MARK: - TripDateFormat

enum TripDateFormat {
    /// "12 Mar – 19 Mar 2027", collapsing to a single date for a same-day trip.
    static func range(from trip: Trip, locale: Locale) -> String {
        let calendar = Calendar.current
        let style = Date.FormatStyle.dateTime.day().month().year().locale(locale)

        guard !calendar.isDate(trip.departureDate, inSameDayAs: trip.returnDate) else {
            return trip.departureDate.formatted(style)
        }

        return "\(trip.departureDate.formatted(style)) – \(trip.returnDate.formatted(style))"
    }
}

// MARK: - TripDisclaimerView

private struct TripDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(LocalizationKeys.tripCheckDisclaimer.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(LocalizationKeys.tripCheckDisclaimerTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .background { Color.backgroundSurface.ignoresSafeArea() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Safety information") {
    TripDisclaimerView()
}

#Preview("With devices") {
    let destination = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
    let trip = Trip(
        countryCode: "JP",
        name: "Tokyo",
        devices: [
            PackDevice(name: "MacBook charger", symbolName: "laptopcomputer", voltage: "100-240V", frequency: "50/60Hz"),
            PackDevice(name: "Hair dryer", symbolName: "wind", voltage: "220-240V", frequency: "50Hz")
        ]
    )

    return NavigationStack {
        TripDetailView(
            trip: trip,
            countries: [destination],
            homeCountry: nil,
            travelPreferencesStore: PreviewTravelPreferencesStore(
                preferences: TravelPreferences(trips: [trip])
            ),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            requestsReviewAfterAppearance: false,
            analyticsTracker: NoopAnalyticsTracker()
        )
    }
}

#Preview("No devices") {
    let destination = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
    let trip = Trip(countryCode: "JP")

    return NavigationStack {
        TripDetailView(
            trip: trip,
            countries: [destination],
            homeCountry: nil,
            travelPreferencesStore: PreviewTravelPreferencesStore(
                preferences: TravelPreferences(trips: [trip])
            ),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            requestsReviewAfterAppearance: false,
            analyticsTracker: NoopAnalyticsTracker()
        )
    }
}
#endif
