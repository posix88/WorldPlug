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
                TripEditorNameSection(
                    viewModel: viewModel,
                    destination: countries.first { $0.code == viewModel.trip.countryCode },
                    showsNameIdeas: !viewModel.isExisting
                )
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
    let destination: Country?
    let showsNameIdeas: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(LocalizationKeys.tripName) {
            // `$viewModel.name` — the optional-to-empty-string projection lives on the view model
            // (see `TripEditorViewModel.name`) instead of a `Binding(get:set:)` built here.
            TextField(LocalizationKeys.tripNamePlaceholder, text: $viewModel.name)

            if showsNameIdeas, let destination {
                TripNameIdeasCloud(destination: destination, name: $viewModel.name)
            }
        }
        .groupedCellSurface()
    }
}

// MARK: - TripNameIdeasCloud

private struct TripNameIdeasCloud: View {
    let destination: Country
    @Binding var name: String
    @Environment(\.locale) private var locale
    @State private var viewModel = TripNameIdeasViewModel()
    @State private var areIdeasVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            HStack(spacing: .xs) {
                Label(LocalizationKeys.tripEditorNameIdeas, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.voltTint)

                if viewModel.isGenerating {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            TripNameIdeasFlowLayout(spacing: .sm) {
                ForEach(Array(viewModel.ideas.enumerated()), id: \.element) { index, idea in
                    Button {
                        name = idea
                    } label: {
                        Text(idea)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .padding(.horizontal, .md)
                            .padding(.vertical, .sm)
                            .background(.voltTint.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.voltTint)
                    .opacity(areIdeasVisible ? 1 : 0)
                    .scaleEffect(areIdeasVisible ? 1 : 0.88)
                    .animation(
                        .bouncy.delay(Double(index) * 0.07),
                        value: areIdeasVisible
                    )
                    .accessibilityLabel(idea)
                }
            }
        }
        .padding(.vertical, .xs)
        .task(id: "\(destination.code)-\(locale.identifier)") {
            areIdeasVisible = false
            await viewModel.generateIdeas(
                for: destination.localizedName(in: locale),
                localeIdentifier: locale.identifier,
                fallbackIdeas: fallbackIdeas
            )
            guard !Task.isCancelled else {
                return
            }

            withAnimation(.bouncy) {
                areIdeasVisible = true
            }
        }
    }

    private var fallbackIdeas: [String] {
        let destinationName = destination.localizedName(in: locale)
        return [
            LocalizationKeys.tripEditorNameIdeaDiscover.string(destinationName),
            LocalizationKeys.tripEditorNameIdeaEscape.string(destinationName),
            LocalizationKeys.tripEditorNameIdeaMyTrip.string(destinationName)
        ]
    }
}

// MARK: - TripNameIdeasFlowLayout

/// A wrapping grid whose items retain their intrinsic width, so short AI-generated names remain
/// compact pills instead of stretching to fill an entire adaptive-grid column.
private struct TripNameIdeasFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let availableWidth = proposal.width ?? .greatestFiniteMagnitude
        var rowWidth: CGFloat = .zero
        var rowHeight: CGFloat = .zero
        var totalHeight: CGFloat = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let requiredWidth = rowWidth == .zero ? size.width : rowWidth + spacing + size.width

            if requiredWidth > availableWidth, rowWidth > .zero {
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = requiredWidth
                rowHeight = max(rowHeight, size.height)
            }
        }

        return CGSize(
            width: proposal.width ?? rowWidth,
            height: totalHeight + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = .zero
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - TripNameIdeasViewModel

@Observable
@MainActor
private final class TripNameIdeasViewModel {
    private let suggester: any TripNameSuggesting
    private(set) var ideas: [String] = []
    private(set) var isGenerating = false

    init(suggester: any TripNameSuggesting = FoundationModelTripNameSuggester()) {
        self.suggester = suggester
    }

    func generateIdeas(
        for destinationName: String,
        localeIdentifier: String,
        fallbackIdeas: [String]
    ) async {
        ideas = fallbackIdeas
        guard suggester.isAvailable else {
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let generatedIdeas = try await suggester.suggestions(
                for: destinationName,
                localeIdentifier: localeIdentifier
            )
            guard !Task.isCancelled, !generatedIdeas.isEmpty else {
                return
            }

            ideas = generatedIdeas
        } catch {
            // Fallback ideas are already visible; a title suggestion must never block trip setup.
        }
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

#Preview("Trip name ideas") {
    @Previewable @State var name = ""

    Form {
        TripNameIdeasCloud(
            destination: Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵"),
            name: $name
        )
    }
    .scrollContentBackground(.hidden)
    .background { AppMeshBackground() }
}
#endif
