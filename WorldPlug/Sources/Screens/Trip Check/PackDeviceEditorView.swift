import SwiftUI

struct PackDeviceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @State private var name = ""
    @State private var symbolName = DeviceIconOption.all[0].symbolName
    @State private var voltage = DeviceElectricalOption.voltages[0]
    @State private var frequency = DeviceElectricalOption.frequencies[0]
    @State private var isIconPickerPresented = false
    @State private var shouldPresentIconPaywall = false
    @State private var isPremiumPaywallPresented = false
    @Binding var scannerValues: DeviceLabelValues?
    let onSave: (PackDevice) -> Void
    let onScanRequested: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .xl) {
                ScanDeviceLabelCard(isPremium: premiumEntitlement.isPremium, action: scanLabel)
                DeviceIdentityCard(name: $name, symbolName: $symbolName) {
                    isIconPickerPresented = true
                }
                DeviceElectricalRatingsCard(voltage: $voltage, frequency: $frequency)
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
            }
        }
        .onChange(of: scannerValues) { _, values in
            guard let values else { return }
            applyScannedValues(values)
        }
        .sheet(isPresented: $isPremiumPaywallPresented) {
            PremiumPaywallView(source: .tripCheck)
        }
        .sheet(isPresented: $isIconPickerPresented, onDismiss: presentIconPaywallIfNeeded) {
            DeviceIconPickerSheet(
                selection: $symbolName,
                isPremium: premiumEntitlement.isPremium,
                onRequestPro: {
                    shouldPresentIconPaywall = true
                    isIconPickerPresented = false
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    private func scanLabel() {
        guard premiumEntitlement.isPremium else {
            isPremiumPaywallPresented = true
            return
        }
        onScanRequested()
    }

    private func applyScannedValues(_ values: DeviceLabelValues) {
        if let parsedVoltage = DeviceElectricalOption.matchingVoltage(values.voltage) {
            voltage = parsedVoltage
        }
        if let parsedFrequency = DeviceElectricalOption.matchingFrequency(values.frequency) {
            frequency = parsedFrequency
        }
    }

    private func saveDevice() {
        onSave(PackDevice(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            symbolName: symbolName,
            voltage: voltage,
            frequency: frequency
        ))
        dismiss()
    }

    private func presentIconPaywallIfNeeded() {
        guard shouldPresentIconPaywall else { return }
        shouldPresentIconPaywall = false
        isPremiumPaywallPresented = true
    }
}

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

private struct DeviceIconOption: Identifiable {
    let symbolName: String
    let accessibilityLabel: String
    let requiresPremium: Bool

    var id: String { symbolName }

    static let all = [
        DeviceIconOption(symbolName: "powerplug.fill", accessibilityLabel: LocalizationKeys.tripCheckDeviceIconPlug.localized, requiresPremium: false),
        DeviceIconOption(symbolName: "iphone", accessibilityLabel: LocalizationKeys.tripCheckDevicePhone.localized, requiresPremium: false),
        DeviceIconOption(symbolName: "laptopcomputer", accessibilityLabel: LocalizationKeys.tripCheckDeviceLaptop.localized, requiresPremium: false),
        DeviceIconOption(symbolName: "camera", accessibilityLabel: LocalizationKeys.tripCheckDeviceCamera.localized, requiresPremium: false),
        DeviceIconOption(symbolName: "bolt.fill", accessibilityLabel: LocalizationKeys.tripCheckDeviceIconOther.localized, requiresPremium: false),
        DeviceIconOption(symbolName: "headphones", accessibilityLabel: LocalizationKeys.tripCheckDeviceHeadphones.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "speaker.wave.2.fill", accessibilityLabel: LocalizationKeys.tripCheckDeviceSpeaker.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "gamecontroller.fill", accessibilityLabel: LocalizationKeys.tripCheckDeviceGameController.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "applewatch", accessibilityLabel: LocalizationKeys.tripCheckDeviceSmartwatch.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "wind", accessibilityLabel: LocalizationKeys.tripCheckDeviceHairDryer.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "sparkles", accessibilityLabel: LocalizationKeys.tripCheckDeviceHairStyler.localized, requiresPremium: true),
        DeviceIconOption(symbolName: "cross.case.fill", accessibilityLabel: LocalizationKeys.tripCheckDeviceCPAP.localized, requiresPremium: true)
    ]
}

private enum DeviceElectricalOption {
    static let voltages = ["100–120V", "100–127V", "100–240V", "110–240V", "220–240V", "230V"]
    static let frequencies = ["50Hz", "60Hz", "50/60Hz"]

    static func matchingVoltage(_ value: String) -> String? {
        let values = numbers(in: value)
        return voltages.first { numbers(in: $0) == values }
    }

    static func matchingFrequency(_ value: String) -> String? {
        let values = numbers(in: value)
        return frequencies.first { numbers(in: $0) == values }
    }

    private static func numbers(in value: String) -> [Int] {
        value.components(separatedBy: .decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .compactMap(Int.init)
    }
}

#if DEBUG
#Preview("Manual device") {
    NavigationStack {
        PackDeviceEditorView(scannerValues: .constant(nil), onSave: { _ in }, onScanRequested: {})
    }
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: false))
}

#Preview("Label scan enabled") {
    NavigationStack {
        PackDeviceEditorView(scannerValues: .constant(nil), onSave: { _ in }, onScanRequested: {})
    }
    .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
}
#endif
