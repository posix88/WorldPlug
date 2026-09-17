import Analytics
import Repository
import SwiftUI

// MARK: - TripEditorView

/// Creates or edits the trip itself — destination, dates, name. Devices are added later, from
/// `TripDetailView`.
struct TripEditorView: View {
    // `locale` moved down to `TripEditorDestinationLabel`, the only thing that read it. A keypath
    // `@Environment` declaration subscribes the view to that key whether the body references it
    // or not, so leaving it here would keep re-evaluating the whole form on locale changes.
    @Environment(\.dismiss) private var dismiss
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
                TripEditorDestinationSection(viewModel: viewModel, countries: countries)
                TripEditorDatesSection(viewModel: viewModel)
                TripEditorNameSection(viewModel: viewModel)
            }
            .onChange(of: viewModel.trip.departureDate) { _, _ in
                viewModel.departureDateChanged()
            }
            .scrollContentBackground(.hidden)
            .groupedCellSurface()
            .background { AppMeshBackground() }
            .navigationTitle(navigationTitle)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isExisting, onDelete != nil {
                    TripEditorRemoveButton(isConfirmationPresented: $isDeleteConfirmationPresented)
                }
            }
            .onAppear {
                analyticsTracker.screen(.tripEditor)
            }
            .confirmationDialog(
                LocalizationKeys.tripRemove,
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(LocalizationKeys.tripRemove, role: .destructive) {
                    onDelete?()
                    dismiss()
                }

                Button(LocalizationKeys.tripCheckCancel, role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(LocalizationKeys.tripCheckCancel)
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
                    .accessibilityLabel(LocalizationKeys.tripCheckAction)
                }
            }
        }
    }

    private var navigationTitle: LocalizedStringResource {
        viewModel.isExisting
            ? LocalizationKeys.tripEditorEditTitle
            : LocalizationKeys.tripEditorNewTitle
    }
}

// MARK: - TripEditorDestinationSection

/// Each `Form` section is its own `View` type rather than a `private var … some View` on
/// `TripEditorView`: a computed property is inlined into the enclosing body, so typing in the
/// name field used to re-evaluate both date pickers and the destination row too.
private struct TripEditorDestinationSection: View {
    let viewModel: TripEditorViewModel
    let countries: [Country]

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(LocalizationKeys.tripDestination) {
            NavigationLink {
                CountryDestinationPickerView(
                    selectedCountryCode: $viewModel.trip.countryCode,
                    countries: countries
                )
            } label: {
                // No inline label: the section header already says "Destination", and repeating it
                // in the row read as a stutter on device.
                TripEditorDestinationLabel(
                    destination: countries.first { $0.code == viewModel.trip.countryCode }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel(LocalizationKeys.tripDestination)
            .accessibilityIdentifier("trip.editor.destination")
        }
        .groupedCellSurface()
    }
}

// MARK: - TripEditorDestinationLabel

private struct TripEditorDestinationLabel: View {
    let destination: Country?
    @Environment(\.locale) private var locale

    var body: some View {
        if let destination {
            Text(verbatim: "\(destination.flagUnicode) \(destination.localizedName(in: locale))")
        } else {
            Text(LocalizationKeys.tripEditorDestinationPlaceholder)
                .foregroundStyle(.textLight)
        }
    }
}

// MARK: - TripEditorDatesSection

private struct TripEditorDatesSection: View {
    let viewModel: TripEditorViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(LocalizationKeys.tripDates) {
            DatePicker(
                LocalizationKeys.tripDeparture,
                selection: $viewModel.trip.departureDate,
                displayedComponents: .date
            )

            DatePicker(
                LocalizationKeys.tripReturnDate,
                selection: $viewModel.returnDate,
                in: viewModel.trip.departureDate...,
                displayedComponents: .date
            )
        }
        .groupedCellSurface()
    }
}

// MARK: - TripEditorNameSection

private struct TripEditorNameSection: View {
    let viewModel: TripEditorViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(LocalizationKeys.tripName) {
            // `$viewModel.name` — the optional-to-empty-string projection lives on the view model
            // (see `TripEditorViewModel.name`) instead of a `Binding(get:set:)` built here.
            TextField(LocalizationKeys.tripNamePlaceholder, text: $viewModel.name)
        }
        .groupedCellSurface()
    }
}

// MARK: - TripEditorRemoveButton

private struct TripEditorRemoveButton: View {
    @Binding var isConfirmationPresented: Bool

    var body: some View {
        Button(role: .destructive) {
            isConfirmationPresented = true
        } label: {
            Label(LocalizationKeys.tripRemove, systemImage: "trash")
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
