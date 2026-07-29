import Analytics
import SwiftUI

// MARK: - PremiumPaywallSource

enum PremiumPaywallSource: String, Identifiable {
    case savedCountries = "saved_countries"
    case countryDetailSave = "country_detail_save"
    case tripCheck = "trip_check"
    case widget = "widget"

    var id: String { rawValue }

    var messageKey: String {
        switch self {
        case .countryDetailSave:
            LocalizationKeys.premiumPaywallCountrySaveMessage
        case .savedCountries, .tripCheck, .widget:
            LocalizationKeys.premiumPaywallMessage
        }
    }
}

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

private struct PremiumPaywallContent: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PremiumPaywallViewModel

    var body: some View {
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
                    benefit(LocalizationKeys.premiumPaywallBenefitSavedCountries, icon: "star.fill")
                    benefit(LocalizationKeys.premiumPaywallBenefitNextTrip, icon: "airplane.departure")
                    benefit(LocalizationKeys.premiumPaywallBenefitWidgets, icon: "rectangle.on.rectangle")
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
                isPresented: errorPresentationBinding
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss.localized, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
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

    private func benefit(_ title: String, icon: String) -> some View {
        Label(title.localized, systemImage: icon)
            .font(.body.weight(.medium))
            .foregroundStyle(.textRegular)
    }

    private var errorPresentationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
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
