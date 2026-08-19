import SwiftUI

// MARK: - PackDeviceEditorView

struct PackDeviceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PackDeviceEditorViewModel
    @Binding var scannerValues: DeviceLabelValues?
    let onSave: (PackDevice) -> Void
    let onScanRequested: () -> Void

    init(
        scannerValues: Binding<DeviceLabelValues?>,
        premiumEntitlement: any PremiumEntitlementProviding,
        onSave: @escaping (PackDevice) -> Void,
        onScanRequested: @escaping () -> Void
    ) {
        _scannerValues = scannerValues
        _viewModel = State(
            initialValue: PackDeviceEditorViewModel(
                premiumEntitlement: premiumEntitlement
            )
        )
        self.onSave = onSave
        self.onScanRequested = onScanRequested
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: .xl) {
                ScanDeviceLabelCard(isPremium: viewModel.isPremium) {
                    if viewModel.scanLabel() {
                        onScanRequested()
                    }
                }
                DeviceIdentityCard(name: $viewModel.name, symbolName: $viewModel.symbolName) {
                    viewModel.isIconPickerPresented = true
                }
                DeviceElectricalRatingsCard(
                    voltage: $viewModel.voltage,
                    frequency: $viewModel.frequency
                )
            }
            .padding(.horizontal, .xxl)
            .padding(.vertical, .xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { Color.backgroundSurface.ignoresSafeArea() }
        .navigationTitle(LocalizationKeys.tripCheckAddDevice.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: saveDevice) { Image(systemName: "checkmark") }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
            }
        }
        .onChange(of: scannerValues) { _, values in
            guard let values else {
                return
            }

            viewModel.applyScannedValues(values)
            // Consume it: `scannedValues` lives on the trip-level view model and outlives this
            // editor instance (a new device editor is pushed for each device added), so leaving
            // it set would mean a *second* device that happens to scan to the exact same
            // voltage/frequency never sees a value change — `onChange` only fires on an actual
            // transition, and the value would already equal what it's being set to.
            scannerValues = nil
        }
        .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
            PremiumPaywallView(source: .tripCheck)
        }
        .sheet(
            isPresented: $viewModel.isIconPickerPresented,
            onDismiss: viewModel.iconPickerDismissed
        ) {
            DeviceIconPickerSheet(
                selection: $viewModel.symbolName,
                isPremium: viewModel.isPremium,
                onRequestPro: viewModel.requestPremiumIcon
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    private func saveDevice() {
        onSave(viewModel.makeDevice())
        dismiss()
    }
}

// MARK: - ScanDeviceLabelCard

private struct ScanDeviceLabelCard: View {
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .lg) {
                Image(systemName: "viewfinder")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.premiumTint)
                    .frame(width: 40, height: 40)
                    .background(.premiumTint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: .xxs) {
                    Text(LocalizationKeys.tripCheckScanLabel.localized)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(LocalizationKeys.tripCheckScanLabelHint.localized)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: .xs)

                Image(systemName: isPremium ? "chevron.right" : "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textLighter)
            }
            .padding(.xl)
            .background(.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.premiumTint.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(LocalizationKeys.tripCheckScanLabelHint.localized)
    }
}

// MARK: - DeviceIdentityCard

private struct DeviceIdentityCard: View {
    @Binding var name: String
    @Binding var symbolName: String
    let onChooseIcon: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: .sm) {
                Text(LocalizationKeys.tripCheckDeviceName.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textRegular)

                HStack(spacing: .md) {
                    TextField(LocalizationKeys.tripCheckDeviceName.localized, text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Button(action: onChooseIcon) {
                        Image(systemName: symbolName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.voltTint)
                            .frame(width: 44, height: 44)
                            .background(.voltTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LocalizationKeys.tripCheckDeviceChooseIcon.localized)
                }
                .padding(.leading, .lg)
                .background(.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

// MARK: - DeviceIconPickerSheet

private struct DeviceIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String
    let isPremium: Bool
    let onRequestPro: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: .lg), count: 4)

    var body: some View {
        VStack(spacing: .xl) {
            Text(LocalizationKeys.tripCheckDeviceChooseIcon.localized)
                .font(.headline)
                .foregroundStyle(.textRegular)

            LazyVGrid(columns: columns, spacing: .lg) {
                ForEach(DeviceIconOption.all) { option in
                    iconButton(for: option)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, .xxl)
        .padding(.vertical, .xl)
        .accessibilityElement(children: .contain)
    }

    private func iconButton(for option: DeviceIconOption) -> some View {
        Button {
            guard isPremium || !option.requiresPremium else {
                onRequestPro()
                return
            }

            selection = option.symbolName
            dismiss()
        } label: {
            Image(systemName: option.symbolName)
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 58)
                .foregroundStyle(selection == option.symbolName ? Color.white : .textRegular)
                .background(
                    selection == option.symbolName ? Color.voltTint : Color.surfaceSecondary,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(alignment: .topTrailing) {
                    if option.requiresPremium && !isPremium {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.xs)
                            .background(.premiumTint, in: Circle())
                            .offset(x: .xs, y: -.xs)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityAddTraits(selection == option.symbolName ? .isSelected : [])
    }
}

// MARK: - DeviceElectricalRatingsCard

private struct DeviceElectricalRatingsCard: View {
    @Binding var voltage: String
    @Binding var frequency: String

    var body: some View {
        Card(spacing: .xl) {
            WheelPicker(
                title: LocalizationKeys.tripCheckDeviceVoltage.localized,
                selection: $voltage,
                options: DeviceElectricalOption.voltages
            )

            Divider()

            WheelPicker(
                title: LocalizationKeys.tripCheckDeviceFrequency.localized,
                selection: $frequency,
                options: DeviceElectricalOption.frequencies
            )
        }
    }
}

// MARK: - WheelPicker

private struct WheelPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.textRegular)

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 120)
            .accessibilityLabel(title)
        }
    }
}

#if DEBUG
#Preview("Manual device") {
    NavigationStack {
        PackDeviceEditorView(
            scannerValues: .constant(nil),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            onSave: { _ in },
            onScanRequested: {}
        )
    }
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: false))
}

#Preview("Label scan enabled") {
    NavigationStack {
        PackDeviceEditorView(
            scannerValues: .constant(nil),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
            onSave: { _ in },
            onScanRequested: {}
        )
    }
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
}
#endif
