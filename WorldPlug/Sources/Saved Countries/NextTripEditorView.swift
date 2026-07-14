import Repository
import SwiftUI

// MARK: - NextTripEditorView

struct NextTripEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var trip: NextTrip
    @State private var returnDate: Date

    let countries: [Country]
    let onSave: (NextTrip) -> Void
    let onDelete: () -> Void
    private let isExisting: Bool

    init(
        trip: NextTrip?,
        countries: [Country],
        onSave: @escaping (NextTrip) -> Void,
        onDelete: @escaping () -> Void
    ) {
        let initialTrip = trip ?? NextTrip(
            countryCode: countries.first?.code ?? "",
            departureDate: .now,
            returnDate: .now
        )

        _trip = State(initialValue: initialTrip)
        _returnDate = State(initialValue: initialTrip.returnDate)
        self.countries = countries
        self.onSave = onSave
        self.onDelete = onDelete
        self.isExisting = trip != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizationKeys.nextTripDestination.localized) {
                    NavigationLink {
                        NextTripDestinationPickerView(
                            selectedCountryCode: $trip.countryCode,
                            countries: countries
                        )
                    } label: {
                        LabeledContent(LocalizationKeys.nextTripDestination.localized) {
                            if let country = countries.first(where: { $0.code == trip.countryCode }) {
                                Text("\(country.flagUnicode) \(country.localizedName(in: locale))")
                            }
                        }
                    }
                }

                Section(LocalizationKeys.nextTripDates.localized) {
                    DatePicker(
                        LocalizationKeys.nextTripDeparture.localized,
                        selection: $trip.departureDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        LocalizationKeys.nextTripReturnDate.localized,
                        selection: $returnDate,
                        in: trip.departureDate...,
                        displayedComponents: .date
                    )
                }

                Section(LocalizationKeys.nextTripName.localized) {
                    TextField(LocalizationKeys.nextTripNamePlaceholder.localized, text: tripNameBinding)
                }

                if isExisting {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel(LocalizationKeys.nextTripRemove.localized)
                    }
                }
            }
            .onChange(of: trip.departureDate) { _, departureDate in
                if returnDate < departureDate {
                    returnDate = departureDate
                }
            }
            .navigationTitle(LocalizationKeys.nextTripTitle.localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(LocalizationKeys.nextTripCancel.localized)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        trip.returnDate = returnDate
                        trip.name = normalizedName
                        onSave(trip)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(LocalizationKeys.nextTripSave.localized)
                    .disabled(trip.countryCode.isEmpty)
                }
            }
        }
    }

    private var tripNameBinding: Binding<String> {
        Binding(
            get: { trip.name ?? "" },
            set: { trip.name = $0 }
        )
    }

    private var normalizedName: String? {
        let name = trip.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }
}
