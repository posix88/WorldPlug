import Analytics
import Repository
import SwiftUI

struct TripCheckResultView: View {
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.locale) private var locale
    let tripCheck: TripCheck
    let countries: [Country]
    @State private var isDisclaimerPresented = false

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
                                    Text(result.device.title).fontWeight(.semibold)
                                    Text(result.status.title).foregroundStyle(statusColor(result.status))
                                    Text(result.message).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: result.status.symbolName).foregroundStyle(statusColor(result.status))
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    disclaimerButton
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ContentUnavailableView(LocalizationKeys.tripCheckUnavailable.localized, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(LocalizationKeys.tripCheckResultTitle.localized)
        .onAppear { analyticsTracker.track(.deviceSafetyResultViewed) }
        .sheet(isPresented: $isDisclaimerPresented) {
            TripCheckDisclaimerView()
        }
    }

    private func statusColor(_ status: DeviceSafetyStatus) -> Color {
        switch status {
        case .ready: .green
        case .adapterNeeded: .blue
        case .checkLabel: .orange
        case .unsafe: .red
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
                        .foregroundStyle(.orange)

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
                .fill(.orange.opacity(0.25))
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
            tripCheck: TripCheck(countryCode: "JP", devices: [.phone, .laptop, .hairDryer]),
            countries: [destination]
        )
    }
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
