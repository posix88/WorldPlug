import Analytics
import AppIntents
import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - TripsView

struct TripsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var viewModel: TripsViewModel
    private let travelPreferencesStore: any TravelPreferencesStoring
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let homeCountryViewModel: any HomeCountryViewModelType
    private let analyticsTracker: any AnalyticsTracker
    private var tripsTip: TripsTip? {
        AppDebugOverrides.isEnabled ? nil : TripsTip()
    }

    init(
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker
    ) {
        _viewModel = State(
            initialValue: TripsViewModel(
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker
            )
        )
        self.travelPreferencesStore = travelPreferencesStore
        self.premiumEntitlement = premiumEntitlement
        self.homeCountryViewModel = homeCountryViewModel
        self.analyticsTracker = analyticsTracker
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                listContent
            }
            .animation(reduceMotion ? nil : .snappy, value: viewModel.hasTrips)
            .scrollContentBackground(.hidden)
            .background { AppMeshBackground() }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(LocalizationKeys.tripsTitle.localized)
            .accessibilityIdentifier("trips.list")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    TripsAddButton(viewModel: viewModel, tip: tripsTip)
                }
            }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                TripEditorView(countries: countries, onSave: viewModel.save)
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .trips)
            }
            .navigationDestination(item: $viewModel.selectedTrip) { trip in
                TripDetailView(
                    trip: trip,
                    countries: countries,
                    homeCountry: homeCountryViewModel.homeCountry,
                    travelPreferencesStore: travelPreferencesStore,
                    premiumEntitlement: premiumEntitlement,
                    requestsReviewAfterAppearance: viewModel.requestsReviewForSelectedTrip,
                    analyticsTracker: analyticsTracker
                )
            }
            .onAppear {
                viewModel.updateCountries(countries)
                viewModel.screenAppeared()
            }
            .onChange(of: countries.count) { _, _ in
                viewModel.updateCountries(countries)
            }
        }
        .tint(.voltTint)
    }

    @ViewBuilder
    private var listContent: some View {
        if !viewModel.hasTrips {
            TripsEmptyState()
        } else {
            TripsSection(kind: .upcoming, viewModel: viewModel)
            TripsSection(kind: .past, viewModel: viewModel)
        }
    }
}

// MARK: - TripsAddButton

private struct TripsAddButton: View {
    let viewModel: TripsViewModel
    let tip: TripsTip?

    var body: some View {
        Button {
            viewModel.beginTrip()
            if viewModel.isEditorPresented {
                tip?.invalidate(reason: .actionPerformed)
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityIdentifier("trips.add")
        .accessibilityLabel(LocalizationKeys.tripsAdd.localized)
        .popoverTip(tip, arrowEdge: .top)
        .appTipIconTint()
    }
}

// MARK: - TripsEmptyState

private struct TripsEmptyState: View {
    var body: some View {
        ContentUnavailableView(
            LocalizationKeys.tripsEmptyTitle.localized,
            systemImage: "suitcase.rolling",
            description: Text(LocalizationKeys.tripsEmptyDescription.localized)
        )
        .padding(.top, .special)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

// MARK: - TripsSection

private struct TripsSection: View {
    enum Kind {
        case upcoming
        case past
    }

    let kind: Kind
    let viewModel: TripsViewModel

    var body: some View {
        let rows = rows

        if !rows.isEmpty {
            Section(title) {
                ForEach(rows) { row in
                    Button {
                        viewModel.select(row.trip)
                    } label: {
                        TripRow(row: row)
                    }
                    .buttonStyle(.plain)
                    .opacity(kind == .past ? 0.5 : 1)
                    .accessibilityIdentifier("trips.row.\(row.country.code)")
                    .appEntityIdentifier(
                        EntityIdentifier(for: TripEntity.self, identifier: row.trip.id)
                    )
                }
                .onDelete(perform: delete)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var rows: [TripRowModel] {
        switch kind {
        case .upcoming: viewModel.upcomingRows
        case .past: viewModel.pastRows
        }
    }

    private var title: String {
        switch kind {
        case .upcoming: LocalizationKeys.tripsSectionUpcoming.localized
        case .past: LocalizationKeys.tripsSectionPast.localized
        }
    }

    /// Deletion is by identity, not by offset into the flat `trips` array — a row's position
    /// within its own section says nothing about its index in the whole list.
    private func delete(at offsets: IndexSet) {
        switch kind {
        case .upcoming: viewModel.deleteUpcoming(at: offsets)
        case .past: viewModel.deletePast(at: offsets)
        }
    }
}

// MARK: - TripRow

/// Body is a single `HStack` — one top-level view — so the enclosing `List` can template row ids
/// from the `ForEach` element alone. Keep it unary if you add to it.
private struct TripRow: View {
    let row: TripRowModel
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: .lg) {
            Text(row.country.flagUnicode)
                .font(.title2)

            VStack(alignment: .leading, spacing: .xxs) {
                TripRowTitle(
                    title: row.trip.name ?? row.country.localizedName(in: locale),
                    isNext: row.isNext
                )

                Text(TripDateFormat.range(from: row.trip, locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !row.trip.devices.isEmpty {
                    TripRowDeviceIcons(devices: row.trip.devices)
                }

                Text(row.safetySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - TripRowTitle

private struct TripRowTitle: View {
    let title: String
    let isNext: Bool

    var body: some View {
        HStack(spacing: .sm) {
            Text(title)
                .font(.body.weight(.semibold))

            if isNext {
                NextTripBadge()
            }
        }
    }
}

// MARK: - TripRowDeviceIcons

private struct TripRowDeviceIcons: View {
    let devices: [PackDevice]

    var body: some View {
        HStack(spacing: -CGFloat.xs) {
            // `prefix(4)` is a cheap slice, fine to take inline.
            ForEach(devices.prefix(4)) { device in
                Image(systemName: device.symbolName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(width: DesignTokens.Size.smallIcon, height: DesignTokens.Size.smallIcon)
                    .background(.tint.opacity(0.12), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.background, lineWidth: 1)
                    }
            }
        }
    }
}

// MARK: - NextTripBadge

private struct NextTripBadge: View {
    var body: some View {
        Text(LocalizationKeys.tripsBadgeNext.localized)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.voltTint)
            .padding(.horizontal, .sm)
            .padding(.vertical, 2)
            .background(.voltTint.opacity(0.14), in: Capsule())
    }
}

// MARK: - TripsTip

private struct TripsTip: Tip {
    var title: Text {
        Text(LocalizationKeys.tripsTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.tripsIntroduction.localized)
    }

    var image: Image? {
        Image(systemName: "suitcase.rolling")
    }
}

#if DEBUG
#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: configuration)
    let destination = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
    container.mainContext.insert(destination)

    let travelPreferencesStore = PreviewTravelPreferencesStore(
        preferences: TravelPreferences(
            trips: [
                Trip(
                    countryCode: "JP",
                    name: "Tokyo",
                    devices: [
                        PackDevice(
                            name: "Phone charger",
                            symbolName: "iphone",
                            voltage: "100-240V",
                            frequency: "50/60Hz"
                        )
                    ]
                ),
                Trip(
                    countryCode: "JP",
                    departureDate: .now - 30 * 24 * 60 * 60,
                    returnDate: .now - 21 * 24 * 60 * 60,
                    name: "Osaka"
                )
            ]
        )
    )

    return TripsView(
        travelPreferencesStore: travelPreferencesStore,
        homeCountryViewModel: PreviewHomeCountryViewModel(),
        premiumEntitlement: PreviewPremiumEntitlement(isPremium: true),
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}
#endif
