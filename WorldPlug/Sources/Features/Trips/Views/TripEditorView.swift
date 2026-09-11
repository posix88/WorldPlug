import Analytics
import Repository
import SwiftUI

// MARK: - TripEditorView

/// Creates or edits the trip itself — destination, dates, name. Devices are added later, from
/// `TripDetailView`.
struct TripEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.analyticsTracker) private var analyticsTracker
    @State private var viewModel: TripEditorViewModel
    @State private var isDeleteConfirmationPresented = false

    let countries: [Country]
    let onSave: (Trip) -> Void
    let onDelete: (() -> Void)?

    init(
        trip: Trip? = nil,
        countries: [Country],
        onSave: @escaping (Trip) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: TripEditorViewModel(trip: trip))
        self.countries = countries
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                destinationSection
                datesSection
                nameSection
            }
            .onChange(of: viewModel.trip.departureDate) { _, _ in
                viewModel.departureDateChanged()
            }
            .scrollContentBackground(.hidden)
            .background { AppMeshBackground() }
            .navigationTitle(navigationTitle)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isExisting, onDelete != nil {
                    removeTripButton
                }
            }
            .onAppear {
                analyticsTracker.screen(.tripEditor)
            }
            .confirmationDialog(
                LocalizationKeys.tripRemove.localized,
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(LocalizationKeys.tripRemove.localized, role: .destructive) {
                    onDelete?()
                    dismiss()
                }

                Button(LocalizationKeys.tripCheckCancel.localized, role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(LocalizationKeys.tripCheckCancel.localized)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(viewModel.save())
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("trip.editor.save")
                    .accessibilityLabel(LocalizationKeys.tripCheckAction.localized)
                }
            }
        }
    }

    private var navigationTitle: String {
        viewModel.isExisting
            ? LocalizationKeys.tripEditorEditTitle.localized
            : LocalizationKeys.tripEditorNewTitle.localized
    }

    private var destinationSection: some View {
        @Bindable var viewModel = viewModel

        return Section(LocalizationKeys.tripDestination.localized) {
            NavigationLink {
                CountryDestinationPickerView(
                    selectedCountryCode: $viewModel.trip.countryCode,
                    countries: countries
                )
            } label: {
                // No inline label: the section header already says "Destination", and repeating it
                // in the row read as a stutter on device.
                destinationLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel(LocalizationKeys.tripDestination.localized)
            .accessibilityIdentifier("trip.editor.destination")
        }
    }

    @ViewBuilder
    private var destinationLabel: some View {
        if let country = countries.first(where: { $0.code == viewModel.trip.countryCode }) {
            Text(verbatim: "\(country.flagUnicode) \(country.localizedName(in: locale))")
        } else {
            Text(LocalizationKeys.tripEditorDestinationPlaceholder.localized)
                .foregroundStyle(.textLight)
        }
    }

    private var datesSection: some View {
        @Bindable var viewModel = viewModel

        return Section(LocalizationKeys.tripDates.localized) {
            DatePicker(
                LocalizationKeys.tripDeparture.localized,
                selection: $viewModel.trip.departureDate,
                displayedComponents: .date
            )

            DatePicker(
                LocalizationKeys.tripReturnDate.localized,
                selection: $viewModel.returnDate,
                in: viewModel.trip.departureDate...,
                displayedComponents: .date
            )
        }
    }

    private var nameSection: some View {
        @Bindable var viewModel = viewModel

        return Section(LocalizationKeys.tripName.localized) {
            TextField(
                LocalizationKeys.tripNamePlaceholder.localized,
                text: Binding(
                    get: { viewModel.trip.name ?? "" },
                    set: { viewModel.trip.name = $0 }
                )
            )
        }
    }

    private var removeTripButton: some View {
        Button(role: .destructive) {
            isDeleteConfirmationPresented = true
        } label: {
            Label(LocalizationKeys.tripRemove.localized, systemImage: "trash")
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
#Preview("New trip") {
    TripEditorView(
        countries: [
            Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹"),
            Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
        ],
        onSave: { _ in }
    )
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}

#Preview("Edit trip") {
    TripEditorView(
        trip: Trip(countryCode: "JP", name: "Tokyo"),
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
