import SwiftUI

// MARK: - OnboardingWelcomeView

// MARK: - OnboardingWelcomeView

struct OnboardingWelcomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onGetStarted: () -> Void

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var featuresVisible = false
    @State private var ctaVisible = false
    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 130
    @ScaledMetric(relativeTo: .largeTitle) private var boltSize: CGFloat = 72

    var body: some View {
        ViewThatFits(in: .vertical) {
            welcomeContent

            ScrollView {
                welcomeContent
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            callToAction
        }
        .onAppear { animateEntrance() }
    }

    private var welcomeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bolt + title
            VStack(spacing: .xxl) {
                ZStack {
                    Circle()
                        .fill(.yellow.opacity(0.12))
                        .frame(width: logoSize, height: logoSize)
                        .blur(radius: 20)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: boltSize, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.boltTop, .boltBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, options: .nonRepeating, isActive: !reduceMotion)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: .md) {
                    Text(LocalizationKeys.appTitle)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Text(LocalizationKeys.onboardingTagline)
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
                    title: LocalizationKeys.onboardingCountriesTitle,
                    subtitle: LocalizationKeys.onboardingCountriesSubtitle
                )
                OnboardingFeatureRow(
                    icon: "house.fill",
                    title: LocalizationKeys.onboardingHomeCountryTitle,
                    subtitle: LocalizationKeys.onboardingHomeCountrySubtitle
                )
                OnboardingFeatureRow(
                    icon: "bolt.shield.fill",
                    title: LocalizationKeys.onboardingAdapterInfoTitle,
                    subtitle: LocalizationKeys.onboardingAdapterInfoSubtitle
                )
            }
            .padding(.horizontal, .max)
            .opacity(featuresVisible ? 1 : 0)
            .offset(y: featuresVisible ? 0 : .xxxl)

            Spacer()
        }
    }

    private var callToAction: some View {
        Button(action: onGetStarted) {
            Text(LocalizationKeys.onboardingGetStarted)
                .font(.headline)
                .foregroundStyle(Color.deepNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, .xxxl)
        .padding(.vertical, .lg)
        .opacity(ctaVisible ? 1 : 0)
        .offset(y: ctaVisible ? 0 : .xl)
    }

    private func animateEntrance() {
        withMotionAwareAnimation(
            .spring(response: 0.7, dampingFraction: 0.65).delay(0.15),
            reduceMotion: reduceMotion
        ) {
            logoScale = 1
            logoOpacity = 1
        }
        withMotionAwareAnimation(
            .easeOut(duration: 0.55).delay(0.55),
            reduceMotion: reduceMotion
        ) {
            featuresVisible = true
        }
        withMotionAwareAnimation(
            .easeOut(duration: 0.45).delay(0.80),
            reduceMotion: reduceMotion
        ) {
            ctaVisible = true
        }
    }
}

// MARK: - OnboardingFeatureRow

struct OnboardingFeatureRow: View {
    let icon: String
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource

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
