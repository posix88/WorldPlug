import Analytics
import Repository
import SwiftUI

struct TripCheckResultView: View {
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.locale) private var locale
    @Environment(\.requestReview) private var requestReview
    let tripCheck: TripCheck
    let countries: [Country]
    let requestsReviewAfterAppearance: Bool
    @State private var isDisclaimerPresented = false

    init(
        tripCheck: TripCheck,
        countries: [Country],
        requestsReviewAfterAppearance: Bool = false
    ) {
        self.tripCheck = tripCheck
        self.countries = countries
        self.requestsReviewAfterAppearance = requestsReviewAfterAppearance
    }

    var body: some View {
        Group {
            if let destination = countries.first(where: { $0.code == tripCheck.countryCode }) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(destination.flagUnicode) \(destination.localizedName(in: locale))")
                                .font(.title2.weight(.bold))
                            Text("\(destination.voltage) · \(destination.frequency)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section(LocalizationKeys.tripCheckSafetySection.localized) {
                        ForEach(TripSafetyChecker.assessments(
                            devices: tripCheck.devices,
                            homeCountry: homeCountryViewModel.homeCountry,
                            destination: destination
                        )) { result in
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.device.name).fontWeight(.semibold)
                                    Text(result.status.title).foregroundStyle(statusColor(result.status))
                                    Text(result.message).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: result.device.symbolName)
                                    .foregroundStyle(statusColor(result.status))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background { Color.backgroundSurface.ignoresSafeArea() }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    disclaimerButton
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ContentUnavailableView(LocalizationKeys.tripCheckUnavailable.localized, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(LocalizationKeys.tripCheckResultTitle.localized)
        .onAppear {
            analyticsTracker.track(.deviceSafetyResultViewed)
            if requestsReviewAfterAppearance {
                AppReviewPrompt.requestAfterSuccessfulAction(using: { requestReview() })
            }
        }
        .sheet(isPresented: $isDisclaimerPresented) {
            TripCheckDisclaimerView()
        }
    }

    private func statusColor(_ status: DeviceSafetyStatus) -> Color {
        switch status {
        case .ready: .statusReady
        case .adapterNeeded: .statusAdapter
        case .checkLabel: .statusCheck
        case .unsafe: .statusUnsafe
        }
    }

    private var disclaimerButton: some View {
        Button {
            isDisclaimerPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationKeys.tripCheckDisclaimerTitle.localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.statusCheck)

                    Text(LocalizationKeys.tripCheckDisclaimerSummary.localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.statusCheck.opacity(0.25))
                .frame(height: 1)
        }
    }
}

private struct TripCheckDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(LocalizationKeys.tripCheckDisclaimer.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(LocalizationKeys.tripCheckDisclaimerTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKeys.premiumPaywallDismiss.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Safety information") {
    TripCheckDisclaimerView()
}
#endif

#if DEBUG
#Preview {
    let destination = Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
    return NavigationStack {
        TripCheckResultView(
            tripCheck: TripCheck(
                countryCode: "JP",
                devices: [
                    PackDevice(name: "MacBook charger", symbolName: "laptopcomputer", voltage: "100-240V", frequency: "50/60Hz"),
                    PackDevice(name: "Hair dryer", symbolName: "wind", voltage: "220-240V", frequency: "50Hz")
                ]
            ),
            countries: [destination]
        )
    }
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
