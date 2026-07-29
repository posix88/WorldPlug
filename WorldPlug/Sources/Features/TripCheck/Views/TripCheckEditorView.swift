import Analytics
import Repository
import SwiftUI

// MARK: - TripCheckEditorView

struct TripCheckEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: TripCheckEditorViewModel
    private let premiumEntitlement: any PremiumEntitlementProviding
    let countries: [Country]
    let onSave: (TripCheck) -> Void

    init(
        countries: [Country],
        premiumEntitlement: any PremiumEntitlementProviding,
        onSave: @escaping (TripCheck) -> Void
    ) {
        _viewModel = State(
            initialValue: TripCheckEditorViewModel(
                countries: countries,
                premiumEntitlement: premiumEntitlement
            )
        )
        self.premiumEntitlement = premiumEntitlement
        self.countries = countries
        self.onSave = onSave
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.navigationPath) {
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
                        onSave(viewModel.save())
                        dismiss()
                    } label: { Image(systemName: "checkmark") }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
                }
            }
            .navigationDestination(for: TripCheckEditorRoute.self) { route in
                switch route {
                case .deviceEditor:
                    PackDeviceEditorView(
                        scannerValues: $viewModel.scannedValues,
                        premiumEntitlement: premiumEntitlement,
                        onSave: viewModel.appendDevice,
                        onScanRequested: viewModel.requestLabelScan
                    )
                case .labelScanner:
                    DeviceLabelScannerView(onRecognized: viewModel.receiveScannedValues)
                }
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .tripCheck)
            }
        }
    }

    private var destinationCard: some View {
        TripCheckEditorCard(title: LocalizationKeys.tripCheckDestination.localized) {
            NavigationLink {
                CountryDestinationPickerView(
                    selectedCountryCode: $viewModel.tripCheck.countryCode,
                    countries: countries
                )
            } label: {
                HStack(spacing: .md) {
                    if let country = countries.first(where: { $0.code == viewModel.tripCheck.countryCode }) {
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
                selection: $viewModel.tripCheck.departureDate,
                displayedComponents: .date
            )

            Divider()

            DatePicker(
                LocalizationKeys.tripCheckReturn.localized,
                selection: $viewModel.returnDate,
                in: viewModel.tripCheck.departureDate...,
                displayedComponents: .date
            )
        }
    }

    private var devicesCard: some View {
        TripCheckEditorCard(title: LocalizationKeys.tripCheckDevices.localized) {
            if viewModel.tripCheck.devices.isEmpty {
                Text(LocalizationKeys.tripCheckDevicesEmpty.localized)
                    .font(.subheadline)
                    .foregroundStyle(.textLight)
            } else {
                ForEach(viewModel.tripCheck.devices) { device in
                    HStack(spacing: .md) {
                        deviceRow(device)

                        Spacer(minLength: .xs)

                        Button {
                            viewModel.removeDevice(id: device.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.statusUnsafe)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(LocalizationKeys.tripCheckRemoveDevice.localized)
                    }
                }
            }

            Button(action: viewModel.addDevice) {
                Label(LocalizationKeys.tripCheckAddDevice.localized, systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.voltTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, viewModel.tripCheck.devices.isEmpty ? .xs : .sm)
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
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
        onSave: { _ in }
    )
}
#endif
