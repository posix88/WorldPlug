import Analytics
import Repository
import SwiftUI

struct TripCheckEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @State private var tripCheck: TripCheck
    @State private var returnDate: Date
    @State private var navigationPath: [TripCheckEditorRoute] = []
    @State private var isPremiumPaywallPresented = false
    let countries: [Country]
    let onSave: (TripCheck) -> Void

    init(countries: [Country], onSave: @escaping (TripCheck) -> Void) {
        let initial = TripCheck(countryCode: countries.first?.code ?? "")
        _tripCheck = State(initialValue: initial)
        _returnDate = State(initialValue: initial.returnDate)
        self.countries = countries
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: .xl) {
                    destinationCard
                    datesCard
                    devicesCard
                }
                .padding(.horizontal, .xxl)
                .padding(.vertical, .xl)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background { Color.backgroundSurface.ignoresSafeArea() }
            .navigationTitle(LocalizationKeys.tripCheckNewTitle.localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(LocalizationKeys.tripCheckCancel.localized)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        tripCheck.returnDate = returnDate
                        onSave(tripCheck)
                        dismiss()
                    } label: { Image(systemName: "checkmark") }
                    .disabled(tripCheck.countryCode.isEmpty || tripCheck.devices.isEmpty)
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
                }
            }
            .navigationDestination(for: TripCheckEditorRoute.self) { route in
                switch route {
                case .deviceEditor:
                    PackDeviceEditorView(
                        scannerValues: $scannedValues,
                        onSave: { device in
                            tripCheck.devices.append(device)
                        },
                        onScanRequested: {
                            navigationPath.append(TripCheckEditorRoute.labelScanner)
                        }
                    )
                case .labelScanner:
                    DeviceLabelScannerView { values in
                        scannedValues = values
                    }
                }
            }
            .sheet(isPresented: $isPremiumPaywallPresented) {
                PremiumPaywallView(source: .tripCheck)
            }
        }
    }

    private var destinationCard: some View {
        TripCheckEditorCard(title: LocalizationKeys.tripCheckDestination.localized) {
            NavigationLink {
                CountryDestinationPickerView(
                    selectedCountryCode: $tripCheck.countryCode,
                    countries: countries
                )
            } label: {
                HStack(spacing: .md) {
                    if let country = countries.first(where: { $0.code == tripCheck.countryCode }) {
                        Text("\(country.flagUnicode) \(country.localizedName(in: locale))")
                            .foregroundStyle(.textRegular)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textLighter)
                }
                .padding(.lg)
                .background(.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var datesCard: some View {
        TripCheckEditorCard(title: LocalizationKeys.tripCheckDates.localized) {
            DatePicker(
                LocalizationKeys.tripCheckDeparture.localized,
                selection: $tripCheck.departureDate,
                displayedComponents: .date
            )

            Divider()

            DatePicker(
                LocalizationKeys.tripCheckReturn.localized,
                selection: $returnDate,
                in: tripCheck.departureDate...,
                displayedComponents: .date
            )
        }
    }

    private var devicesCard: some View {
        TripCheckEditorCard(title: LocalizationKeys.tripCheckDevices.localized) {
            if tripCheck.devices.isEmpty {
                Text(LocalizationKeys.tripCheckDevicesEmpty.localized)
                    .font(.subheadline)
                    .foregroundStyle(.textLight)
            } else {
                ForEach(tripCheck.devices) { device in
                    HStack(spacing: .md) {
                        deviceRow(device)

                        Spacer(minLength: .xs)

                        Button {
                            tripCheck.devices.removeAll { $0.id == device.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.statusUnsafe)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(LocalizationKeys.tripCheckRemoveDevice.localized)
                    }
                }
            }

            Button(action: addDevice) {
                Label(LocalizationKeys.tripCheckAddDevice.localized, systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.voltTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, tripCheck.devices.isEmpty ? .xs : .sm)
            }
            .buttonStyle(.plain)
        }
    }

    private func deviceRow(_ device: PackDevice) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                Text([device.voltage, device.frequency].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: device.symbolName)
        }
    }

    private func addDevice() {
        guard premiumEntitlement.isPremium || tripCheck.devices.isEmpty else {
            isPremiumPaywallPresented = true
            return
        }
        navigationPath.append(TripCheckEditorRoute.deviceEditor)
    }

    @State private var scannedValues: DeviceLabelValues?
}

private enum TripCheckEditorRoute: Hashable {
    case deviceEditor
    case labelScanner
}

private struct TripCheckEditorCard<Content: View>: View {
    let title: String
    private let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Card(spacing: .xl) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.textRegular)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: .lg) {
                content()
            }
        }
    }
}

#if DEBUG
#Preview {
    TripCheckEditorView(
        countries: [Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")],
        onSave: { _ in }
    )
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
}
#endif
