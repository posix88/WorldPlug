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

        // Deliberately no `NavigationStack` here: this view is pushed onto `TripsView`'s stack, so
        // owning one would nest a stack inside a stack. The device editor is a sheet, and it
        // carries the one stack it needs for the scanner push.
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
                    premiumEntitlement: premiumEntitlement,
                    onSave: viewModel.appendDevice,
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
            .background { Color.backgroundSurface.ignoresSafeArea() }
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
                VStack(alignment: .leading, spacing: .sm) {
                    Text("\(destination.flagUnicode) \(destination.localizedName(in: locale))")
                        .font(.title2.weight(.bold))

                    Text(TripDateFormat.range(from: viewModel.trip, locale: locale))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(destination.voltage) · \(destination.frequency)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            if viewModel.trip.devices.isEmpty {
                ContentUnavailableView(
                    LocalizationKeys.tripDetailDevicesEmptyTitle.localized,
                    systemImage: "powerplug",
                    description: Text(LocalizationKeys.tripDetailDevicesEmptyDescription.localized)
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.assessments) { assessment in
                    assessmentRow(assessment)
                }
            }

            addDeviceButton
        }
    }

    private func assessmentRow(_ assessment: DeviceSafetyAssessment) -> some View {
        let color = Self.statusColor(assessment.status)

        return Label {
            VStack(alignment: .leading, spacing: .xxs) {
                Text(assessment.device.name).fontWeight(.semibold)
                Text(assessment.status.title).foregroundStyle(color)
                Text(assessment.message).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: assessment.device.symbolName)
                .foregroundStyle(color)
        }
        .appEntityIdentifier(
            EntityIdentifier(for: PackDeviceEntity.self, identifier: assessment.device.id)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.removeDevice(id: assessment.device.id)
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel(LocalizationKeys.tripCheckRemoveDevice.localized)
        }
    }

    private var addDeviceButton: some View {
        Button(action: viewModel.addDevice) {
            Label(LocalizationKeys.tripCheckAddDevice.localized, systemImage: "plus")
                .font(.body.weight(.semibold))
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

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.interactive())
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.statusCheck.opacity(0.25))
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
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

// MARK: - PackDeviceEditorSheet

/// Wraps the device editor in the one `NavigationStack` it needs, so the label scanner can be
/// pushed on top of it without `TripDetailView` — which is itself already inside a stack — having
/// to own a second one.
private struct PackDeviceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [PackDeviceEditorRoute]
    @Binding var scannerValues: DeviceLabelValues?
    let premiumEntitlement: any PremiumEntitlementProviding
    let onSave: (PackDevice) -> Void
    let onScanRequested: () -> Void

    var body: some View {
        NavigationStack(path: $path) {
            PackDeviceEditorView(
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKeys.premiumPaywallDismiss.localized) {
                        dismiss()
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
