import Analytics
import AppIntents
import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - TripCheckView

struct TripCheckView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var viewModel: TripCheckViewModel
    private let premiumEntitlement: any PremiumEntitlementProviding
    private let homeCountryViewModel: any HomeCountryViewModelType
    private let analyticsTracker: any AnalyticsTracker
    private let tripCheckTip = TripCheckTip()

    init(
        travelPreferencesStore: any TravelPreferencesStoring,
        homeCountryViewModel: any HomeCountryViewModelType,
        premiumEntitlement: any PremiumEntitlementProviding,
        analyticsTracker: any AnalyticsTracker
    ) {
        _viewModel = State(
            initialValue: TripCheckViewModel(
                travelPreferencesStore: travelPreferencesStore,
                homeCountryViewModel: homeCountryViewModel,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker
            )
        )
        self.premiumEntitlement = premiumEntitlement
        self.homeCountryViewModel = homeCountryViewModel
        self.analyticsTracker = analyticsTracker
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.tripChecks.isEmpty {
                    ContentUnavailableView(
                        LocalizationKeys.tripCheckEmptyTitle.localized,
                        systemImage: "suitcase.rolling",
                        description: Text(LocalizationKeys.tripCheckEmptyDescription.localized)
                    )
                    .padding(.top, .special)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    Section(LocalizationKeys.tripCheckYourTrips.localized) {
                        ForEach(viewModel.rows) { row in
                            Button {
                                viewModel.select(row.tripCheck)
                            } label: {
                                TripCheckRow(row: row)
                            }
                            .buttonStyle(.plain)
                            .appEntityIdentifier(
                                EntityIdentifier(for: CountryEntity.self, identifier: row.country.code)
                            )
                        }
                        .onDelete(perform: viewModel.delete)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: viewModel.tripChecks.isEmpty)
            .scrollContentBackground(.hidden)
            .background { AppMeshBackground() }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(LocalizationKeys.tripCheckTitle.localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.beginTripCheck()
                        if viewModel.isEditorPresented {
                            tripCheckTip.invalidate(reason: .actionPerformed)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(LocalizationKeys.tripCheckAdd.localized)
                    .popoverTip(tripCheckTip, arrowEdge: .top)
                    .appTipIconTint()
                }
            }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                TripCheckEditorView(
                    countries: countries,
                    initialCountryCode: viewModel.initialCountryCode,
                    premiumEntitlement: premiumEntitlement
                ) {
                    viewModel.save($0)
                }
            }
            .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                PremiumPaywallView(source: .tripCheck)
            }
            .navigationDestination(item: $viewModel.selectedTripCheck) { tripCheck in
                TripCheckResultView(
                    tripCheck: tripCheck,
                    countries: countries,
                    homeCountry: homeCountryViewModel.homeCountry,
                    requestsReviewAfterAppearance: viewModel.requestsReviewForSelectedTrip,
                    analyticsTracker: analyticsTracker
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .onAppear {
                viewModel.updateCountries(countries)
                viewModel.screenAppeared()
            }
            .onChange(of: countries.map(\.code)) { _, _ in
                viewModel.updateCountries(countries)
            }
        }
    }
}

// MARK: - TripCheckRow

private struct TripCheckRow: View {
    let row: TripCheckRowModel
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: .lg) {
            Text(row.country.flagUnicode)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(row.tripCheck.name ?? row.country.localizedName(in: locale))
                    .font(.body.weight(.semibold))

                HStack(spacing: -CGFloat.xs) {
                    ForEach(Array(row.tripCheck.devices.prefix(4))) { device in
                        Image(systemName: device.symbolName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tint)
                            .frame(width: DesignTokens.Size.smallIcon, height: DesignTokens.Size.smallIcon)
                            .background(.tint.opacity(0.12), in: Circle())
                            .overlay(Circle().stroke(.background, lineWidth: 1))
                    }
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

// MARK: - TripCheckTip

private struct TripCheckTip: Tip {
    var title: Text {
        Text(LocalizationKeys.tripCheckTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.tripCheckIntroduction.localized)
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
            tripChecks: [
                TripCheck(
                    countryCode: "JP",
                    devices: [
                        PackDevice(
                            name: "Phone charger",
                            symbolName: "iphone",
                            voltage: "100-240V",
                            frequency: "50/60Hz"
                        )
                    ]
                )
            ]
        )
    )
    let homeCountryViewModel = PreviewHomeCountryViewModel()
    let premiumEntitlement = PreviewPremiumEntitlement(isPremium: true)

    return TripCheckView(
        travelPreferencesStore: travelPreferencesStore,
        homeCountryViewModel: homeCountryViewModel,
        premiumEntitlement: premiumEntitlement,
        analyticsTracker: NoopAnalyticsTracker()
    )
    .modelContainer(container)
}
#endif
