import Repository
import SwiftData
import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @State private var page: Int = 0

    let onComplete: () -> Void

    init(modelContext: ModelContext, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: OnboardingViewModel(modelContext: modelContext))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            OnboardingBackground().ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingWelcomeView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { page = 1 }
                }
                .tag(0)

                OnboardingPickerView(viewModel: viewModel, onComplete: onComplete)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)
    for code in ["IT", "GB", "US", "JP", "DE", "FR", "AU", "BR"] {
        container.mainContext.insert(
            Country(code: code, voltage: "230V", frequency: "50Hz", flagUnicode: "🏳️")
        )
    }
    let homeVM = HomeCountryViewModel(
        store: UserDefaultsHomeCountryStore(),
        modelContext: container.mainContext
    )
    return OnboardingView(modelContext: container.mainContext, onComplete: {})
        .environment(homeVM)
}
#endif
