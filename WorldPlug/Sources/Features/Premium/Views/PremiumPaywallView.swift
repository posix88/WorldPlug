import Analytics
import SwiftUI

// MARK: - PremiumPaywallSource

enum PremiumPaywallSource: String, Identifiable {
    case savedCountries = "saved_countries"
    case countryDetailSave = "country_detail_save"
    case trips
    case widget

    var id: String { rawValue }

    var messageKey: String {
        switch self {
        case .countryDetailSave:
            LocalizationKeys.premiumPaywallCountrySaveMessage
        case .savedCountries, .trips, .widget:
            LocalizationKeys.premiumPaywallMessage
        }
    }
}

// MARK: - PremiumBenefitRow

private struct PremiumBenefitRow: View {
    let key: String
    let icon: String

    var body: some View {
        Label(key.localized, systemImage: icon)
            .font(.body.weight(.medium))
            .foregroundStyle(.textRegular)
    }
}

// MARK: - PremiumPaywallView

struct PremiumPaywallView: View {
    let source: PremiumPaywallSource
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.analyticsTracker) private var analyticsTracker

    var body: some View {
        PremiumPaywallContent(
            viewModel: PremiumPaywallViewModel(
                source: source,
                premiumEntitlement: premiumEntitlement,
                analyticsTracker: analyticsTracker
            )
        )
    }

    init(source: PremiumPaywallSource = .savedCountries) {
        self.source = source
    }
}

// MARK: - PremiumPaywallContent

private struct PremiumPaywallContent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumPaywallViewModel

    /// Marking `viewModel` `private` narrows the auto-synthesized memberwise init's access to
    /// inside this type only — a top-level `private struct` alone would be file-scoped, but a
    /// `private` *member* caps the init to the enclosing type itself. An explicit init (not
    /// marked `private`) restores the file-wide access `PremiumPaywallView.body` below needs.
    init(viewModel: PremiumPaywallViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: .xxl) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 88, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.premiumTint)

                VStack(spacing: .sm) {
                    Text(LocalizationKeys.premiumPaywallTitle.localized)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.textRegular)

                    Text(viewModel.source.messageKey.localized)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.textLight)
                }

                VStack(alignment: .leading, spacing: .lg) {
                    PremiumBenefitRow(key: LocalizationKeys.premiumPaywallBenefitSavedCountries, icon: "star.fill")
                    PremiumBenefitRow(key: LocalizationKeys.premiumPaywallBenefitNextTrip, icon: "airplane.departure")
                    PremiumBenefitRow(key: LocalizationKeys.premiumPaywallBenefitWidgets, icon: "rectangle.on.rectangle")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button(action: purchasePremium) {
                    Group {
                        if viewModel.isPurchasing {
                            ProgressView()
                        } else if let premiumPrice = viewModel.premiumPrice {
                            Text(LocalizationKeys.premiumPaywallPurchaseWithPrice.localized(premiumPrice))
                        } else {
                            Text(LocalizationKeys.premiumPaywallPurchase.localized)
                        }
                    }
                    .frame(minWidth: 260)
                }
                .buttonStyle(.glassProminent)
                .tint(.premiumTint)
                .controlSize(.large)
                .disabled(viewModel.isPurchasing)

                Button(LocalizationKeys.premiumPaywallRestore.localized, action: restorePurchases)
                    .buttonStyle(.glass)
                    .tint(.textRegular)
                    .disabled(viewModel.isPurchasing)
            }
            .frame(maxWidth: 480)
            .padding(.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppMeshBackground() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(LocalizationKeys.generalClose.localized)
                }
            }
            .alert(
                LocalizationKeys.premiumPaywallErrorTitle.localized,
                isPresented: $viewModel.isErrorAlertPresented
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss.localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(
                LocalizationKeys.premiumPaywallPendingTitle.localized,
                isPresented: $viewModel.isPendingAlertPresented
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss.localized, role: .cancel) {}
            } message: {
                Text(LocalizationKeys.premiumPaywallPendingMessage.localized)
            }
            .onChange(of: viewModel.isPremium) { _, isPremium in
                if isPremium {
                    dismiss()
                }
            }
            .onAppear {
                viewModel.screenAppeared()
            }
            .task {
                await viewModel.loadProduct()
            }
        }
    }

    private func purchasePremium() {
        Task {
            await viewModel.purchase()
        }
    }

    private func restorePurchases() {
        Task {
            await viewModel.restore()
        }
    }
}

#if DEBUG
#Preview {
    PremiumPaywallView()
        .environment(\.premiumEntitlement, PreviewPremiumEntitlement(isPremium: false))
}
#endif
