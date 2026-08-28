import Analytics
import Repository
import SwiftUI

// MARK: - NextTripEditorView

struct NextTripEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.analyticsTracker) private var analyticsTracker
    @State private var viewModel: NextTripEditorViewModel
    @State private var isDeleteConfirmationPresented = false

    let countries: [Country]
    let onSave: (NextTrip) -> Void
    let onDelete: () -> Void

    init(
        trip: NextTrip?,
        countries: [Country],
        onSave: @escaping (NextTrip) -> Void,
        onDelete: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: NextTripEditorViewModel(trip: trip, countries: countries)
        )
        self.countries = countries
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section(LocalizationKeys.nextTripDestination.localized) {
                    NavigationLink {
                        CountryDestinationPickerView(
                            selectedCountryCode: $viewModel.trip.countryCode,
                            countries: countries
                        )
                    } label: {
                        LabeledContent(LocalizationKeys.nextTripDestination.localized) {
                            if let country = countries.first(where: { $0.code == viewModel.trip.countryCode }) {
                                Text("\(country.flagUnicode) \(country.localizedName(in: locale))")
                            }
                        }
                    }
                }

                Section(LocalizationKeys.nextTripDates.localized) {
                    DatePicker(
                        LocalizationKeys.nextTripDeparture.localized,
                        selection: $viewModel.trip.departureDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        LocalizationKeys.nextTripReturnDate.localized,
                        selection: $viewModel.returnDate,
                        in: viewModel.trip.departureDate...,
                        displayedComponents: .date
                    )
                }

                Section(LocalizationKeys.nextTripName.localized) {
                    TextField(
                        LocalizationKeys.nextTripNamePlaceholder.localized,
                        text: Binding(
                            get: { viewModel.trip.name ?? "" },
                            set: { viewModel.trip.name = $0 }
                        )
                    )
                }
            }
            .onChange(of: viewModel.trip.departureDate) { _, _ in
                viewModel.departureDateChanged()
            }
            .navigationTitle(LocalizationKeys.nextTripTitle.localized)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isExisting {
                    removeTripButton
                }
            }
            .onAppear {
                analyticsTracker.screen(.nextTrip)
            }
            .confirmationDialog(
                LocalizationKeys.nextTripRemove.localized,
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(LocalizationKeys.nextTripRemove.localized, role: .destructive) {
                    onDelete()
                    dismiss()
                }

                Button(LocalizationKeys.nextTripCancel.localized, role: .cancel) {}
            }
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
                        onSave(viewModel.save())
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(LocalizationKeys.nextTripSave.localized)
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private var removeTripButton: some View {
        Button(role: .destructive) {
            isDeleteConfirmationPresented = true
        } label: {
            Label(LocalizationKeys.nextTripRemove.localized, systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(.statusUnsafe)
        .padding(.horizontal, .xxl)
        .padding(.vertical, .md)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#if DEBUG
#Preview {
    NextTripEditorView(
        trip: NextTrip(countryCode: "JP", departureDate: .now, returnDate: .now, name: "Tokyo"),
        countries: [
            Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹"),
            Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        ],
        onSave: { _ in },
        onDelete: {}
    )
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
