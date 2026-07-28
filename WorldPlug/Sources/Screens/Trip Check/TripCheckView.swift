import Analytics
import Repository
import SwiftData
import SwiftUI
import TipKit

struct TripCheckView: View {
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var isEditorPresented = false
    @State private var isPremiumPaywallPresented = false
    @State private var selectedTripCheck: TripCheck?
    @State private var requestsReviewForSelectedTrip = false
    private let tripCheckTip = TripCheckTip()

    var body: some View {
        NavigationStack {
            List {
                if tripChecks.isEmpty {
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
                        ForEach(tripChecks) { tripCheck in
                            Button {
                                requestsReviewForSelectedTrip = false
                                selectedTripCheck = tripCheck
                            } label: {
                                tripCheckRow(tripCheck)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteTripChecks)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: tripChecks.isEmpty)
            .scrollContentBackground(.hidden)
            .background { AppMeshBackground() }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(LocalizationKeys.tripCheckTitle.localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: beginTripCheck) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(LocalizationKeys.tripCheckAdd.localized)
                    .popoverTip(tripCheckTip, arrowEdge: .top)
                    .appTipIconTint()
                }
            }
            .sheet(isPresented: $isEditorPresented) {
                TripCheckEditorView(countries: countries) { tripCheck in
                    travelPreferencesStore.saveTripCheck(tripCheck)
                    analyticsTracker.track(.tripCheckCompleted)
                    requestsReviewForSelectedTrip = true
                    selectedTripCheck = tripCheck
                }
            }
            .sheet(isPresented: $isPremiumPaywallPresented) {
                PremiumPaywallView(source: .tripCheck)
            }
            .navigationDestination(item: $selectedTripCheck) { tripCheck in
                TripCheckResultView(
                    tripCheck: tripCheck,
                    countries: countries,
                    requestsReviewAfterAppearance: requestsReviewForSelectedTrip
                )
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .onAppear {
                analyticsTracker.screen(.nextTrip)
            }
        }
    }

    private var tripChecks: [TripCheck] {
        travelPreferencesStore.preferences.tripChecks.sorted { $0.departureDate < $1.departureDate }
    }

    private func beginTripCheck() {
        guard premiumEntitlement.isPremium || tripChecks.count < 1 else {
            analyticsTracker.track(.tripCheckLimitReached)
            isPremiumPaywallPresented = true
            return
        }
        analyticsTracker.track(.tripCheckStarted)
        tripCheckTip.invalidate(reason: .actionPerformed)
        isEditorPresented = true
    }

    private func deleteTripChecks(at offsets: IndexSet) {
        for index in offsets {
            travelPreferencesStore.removeTripCheck(id: tripChecks[index].id)
        }
    }

    private func tripCheckRow(_ tripCheck: TripCheck) -> some View {
        HStack(spacing: 12) {
            if let country = countries.first(where: { $0.code == tripCheck.countryCode }) {
                let assessments = TripSafetyChecker.assessments(
                    devices: tripCheck.devices,
                    homeCountry: homeCountryViewModel.homeCountry,
                    destination: country
                )

                Text(country.flagUnicode)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(tripCheck.name ?? country.localizedName(in: locale))
                        .font(.body.weight(.semibold))

                    HStack(spacing: -4) {
                        ForEach(Array(tripCheck.devices.prefix(4))) { device in
                            Image(systemName: device.symbolName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tint)
                                .frame(width: 22, height: 22)
                                .background(.tint.opacity(0.12), in: Circle())
                                .overlay(Circle().stroke(.background, lineWidth: 1))
                        }
                    }

                    Text(safetySummary(assessments))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func safetySummary(_ assessments: [DeviceSafetyAssessment]) -> String {
        let statuses: [DeviceSafetyStatus] = [.unsafe, .checkLabel, .adapterNeeded, .ready]
        return statuses.compactMap { status in
            let count = assessments.filter { $0.status == status }.count
            return count == 0 ? nil : "\(count) \(status.title)"
        }
        .joined(separator: " · ")
    }
}


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

    return TripCheckView()
        .modelContainer(container)
        .environment(
            \.travelPreferencesStore,
            PreviewTravelPreferencesStore(
                preferences: TravelPreferences(
                    tripChecks: [
                        TripCheck(
                            countryCode: "JP",
                            devices: [PackDevice(name: "Phone charger", symbolName: "iphone", voltage: "100-240V", frequency: "50/60Hz")]
                        )
                    ]
                )
            )
        )
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
        .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: true))
        .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
