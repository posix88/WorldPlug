import SwiftUI

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: .xxl) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 88, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)

                VStack(spacing: .sm) {
                    Text(LocalizationKeys.premiumPaywallTitle.localized)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.textRegular)

                    Text(LocalizationKeys.premiumPaywallMessage.localized)
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
                        if isPurchasing {
                            ProgressView()
                        } else {
                            Text(LocalizationKeys.premiumPaywallPurchase.localized)
                        }
                    }
                    .frame(minWidth: 260)
                }
                .buttonStyle(.glassProminent)
                .tint(.blue)
                .controlSize(.large)
                .disabled(isPurchasing)

                Button(LocalizationKeys.premiumPaywallRestore.localized, action: restorePurchases)
                    .buttonStyle(.glass)
                    .tint(.textRegular)
                    .disabled(isPurchasing)
            }
            .frame(maxWidth: 480)
            .padding(.xxl)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(
                LocalizationKeys.premiumPaywallErrorTitle.localized,
                isPresented: errorPresentationBinding
            ) {
                Button(LocalizationKeys.premiumPaywallDismiss.localized, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: premiumEntitlement.isPremium) { _, isPremium in
                if isPremium {
                    dismiss()
                }
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
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func purchasePremium() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                _ = try await premiumEntitlement.purchasePremium()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await premiumEntitlement.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    PremiumPaywallView()
}
#endif
