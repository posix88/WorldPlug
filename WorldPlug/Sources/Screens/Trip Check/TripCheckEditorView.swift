import Analytics
import Repository
import SwiftUI

struct TripCheckEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var tripCheck: TripCheck
    @State private var returnDate: Date
    let countries: [Country]
    let onSave: (TripCheck) -> Void

    init(countries: [Country], onSave: @escaping (TripCheck) -> Void) {
        let initial = TripCheck(countryCode: countries.first?.code ?? "", devices: [.phone, .laptop])
        _tripCheck = State(initialValue: initial)
        _returnDate = State(initialValue: initial.returnDate)
        self.countries = countries
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizationKeys.tripCheckDestination.localized) {
                    NavigationLink {
                        CountryDestinationPickerView(
                            selectedCountryCode: $tripCheck.countryCode,
                            countries: countries
                        )
                    } label: {
                        LabeledContent(LocalizationKeys.tripCheckDestination.localized) {
                            if let country = countries.first(where: { $0.code == tripCheck.countryCode }) {
                                Text("\(country.flagUnicode) \(country.localizedName(in: locale))")
                            }
                        }
                    }
                }
                Section(LocalizationKeys.tripCheckDates.localized) {
                    DatePicker(LocalizationKeys.tripCheckDeparture.localized, selection: $tripCheck.departureDate, displayedComponents: .date)
                    DatePicker(LocalizationKeys.tripCheckReturn.localized, selection: $returnDate, in: tripCheck.departureDate..., displayedComponents: .date)
                }
                Section(LocalizationKeys.tripCheckDeviceSection.localized) {
                    ForEach(TravelDevice.allCases) { device in
                        Toggle(isOn: deviceBinding(device)) {
                            Label(device.title, systemImage: device.symbolName)
                        }
                    }
                }
            }
            .navigationTitle(LocalizationKeys.tripCheckNewTitle.localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(LocalizationKeys.tripCheckCancel.localized)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        tripCheck.returnDate = returnDate
                        onSave(tripCheck)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(tripCheck.countryCode.isEmpty || tripCheck.devices.isEmpty)
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
                }
            }
        }
    }

    private func deviceBinding(_ device: TravelDevice) -> Binding<Bool> {
        Binding(
            get: { tripCheck.devices.contains(device) },
            set: { isSelected in
                if isSelected { tripCheck.devices.append(device) }
                else { tripCheck.devices.removeAll { $0 == device } }
            }
        )
    }
}

#if DEBUG
#Preview {
    TripCheckEditorView(
        countries: [
            Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹"),
            Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        ],
        onSave: { _ in }
    )
}
#endif
