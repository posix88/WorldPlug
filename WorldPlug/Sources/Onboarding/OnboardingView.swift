import Analytics
import Repository
import SwiftData
import SwiftUI

// MARK: - OnboardingView

struct OnboardingView<ViewModel: OnboardingViewModelType>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.analyticsTracker) private var analyticsTracker
    @State private var viewModel: ViewModel
    @State private var page: Int = 0

    let onComplete: () -> Void

    init(viewModel: ViewModel, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            OnboardingBackground().ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingWelcomeView {
                    withMotionAwareAnimation(
                        .spring(response: 0.55, dampingFraction: 0.82),
                        reduceMotion: reduceMotion
                    ) {
                        page = 1
                    }
                }
                .tag(0)

                OnboardingPickerView(viewModel: viewModel, onComplete: onComplete)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            analyticsTracker.screen(.onboarding)
        }
    }
}

extension OnboardingView where ViewModel == OnboardingViewModel {
    init(modelContext: ModelContext, onComplete: @escaping () -> Void) {
        self.init(viewModel: OnboardingViewModel(modelContext: modelContext), onComplete: onComplete)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let countries = ["IT", "GB", "US", "JP", "DE", "FR", "AU", "BR"].map {
        Country(code: $0, voltage: "230V", frequency: "50Hz", flagUnicode: "🏳️")
    }
    return OnboardingView(viewModel: PreviewOnboardingViewModel(countries: countries), onComplete: {})
        .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
}
#endif
