import SwiftUI

// MARK: - OnboardingWelcomeView

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var featuresVisible = false
    @State private var ctaVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bolt + title
            VStack(spacing: .xxl) {
                ZStack {
                    Circle()
                        .fill(.yellow.opacity(0.12))
                        .frame(width: 130, height: 130)
                        .blur(radius: 20)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 72, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.boltTop, .boltBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, options: .nonRepeating)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: .md) {
                    Text(String(localized: "Voltly"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(String(localized: "Always travel plug‑ready."))
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .opacity(logoOpacity)
            }

            Spacer()

            // Feature rows
            VStack(alignment: .leading, spacing: .xxl) {
                OnboardingFeatureRow(
                    icon: "globe.europe.africa.fill",
                    title: String(localized: "200+ countries"),
                    subtitle: String(localized: "Plug standards, voltage & frequency covered")
                )
                OnboardingFeatureRow(
                    icon: "house.fill",
                    title: String(localized: "Home country"),
                    subtitle: String(localized: "Instant compatibility checks when you travel")
                )
                OnboardingFeatureRow(
                    icon: "bolt.shield.fill",
                    title: String(localized: "Adapter info"),
                    subtitle: String(localized: "Know exactly what you need before you pack")
                )
            }
            .padding(.horizontal, .max)
            .opacity(featuresVisible ? 1 : 0)
            .offset(y: featuresVisible ? 0 : .xxxl)

            Spacer()

            // CTA
            Button(action: onGetStarted) {
                Text(String(localized: "Get Started"))
                    .font(.headline)
                    .foregroundStyle(Color.deepNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, .xxxl)
            .padding(.bottom, 52)
            .opacity(ctaVisible ? 1 : 0)
            .offset(y: ctaVisible ? 0 : .xl)
        }
        .onAppear { animateEntrance() }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.15)) {
            logoScale = 1
            logoOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.55)) {
            featuresVisible = true
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.80)) {
            ctaVisible = true
        }
    }
}

// MARK: - OnboardingFeatureRow

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: .xl) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.yellow)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: .xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        OnboardingBackground().ignoresSafeArea()
        OnboardingWelcomeView(onGetStarted: {})
    }
}
#endif
