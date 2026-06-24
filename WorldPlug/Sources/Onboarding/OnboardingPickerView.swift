import Repository
import SwiftUI

// MARK: - OnboardingPickerView

struct OnboardingPickerView: View {
    @Environment(HomeCountryViewModel.self) private var homeViewModel
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header — naturally collapses when keyboard appears
            VStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(.top, 60)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text(String(localized: "Where's home?"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(String(localized: "We'll show plug compatibility\nfor every country you visit."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.45))

                TextField(
                    String(localized: "Search country…"),
                    text: $viewModel.searchQuery
                )
                .foregroundStyle(.white)
                .tint(.yellow)
                .submitLabel(.search)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Country list — fills remaining space, dismisses keyboard on swipe
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.filteredCountries) { country in
                        OnboardingCountryRow(
                            country: country,
                            isSelected: viewModel.selectedCountry?.code == country.code
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                let alreadySelected = viewModel.selectedCountry?.code == country.code
                                viewModel.selectedCountry = alreadySelected ? nil : country
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // CTA floats above the keyboard automatically via safeAreaInset
        .safeAreaInset(edge: .bottom, spacing: 0) {
            pickerCTA
        }
    }

    // MARK: - CTA

    private var pickerCTA: some View {
        VStack(spacing: 10) {
            Button {
                if let selected = viewModel.selectedCountry {
                    homeViewModel.setHome(code: selected.code)
                }
                onComplete()
            } label: {
                Group {
                    if let selected = viewModel.selectedCountry {
                        Label(
                            "\(selected.flagUnicode)  \(selected.name)",
                            systemImage: "arrow.right"
                        )
                        .labelStyle(TrailingIconLabelStyle())
                    } else {
                        Text(String(localized: "Select a country above"))
                    }
                }
                .font(.headline)
                .foregroundStyle(
                    viewModel.selectedCountry != nil
                        ? Color.deepNavy
                        : .white.opacity(0.35)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    viewModel.selectedCountry != nil ? .yellow : .white.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .animation(.spring(response: 0.4), value: viewModel.selectedCountry?.code)
            }
            .disabled(viewModel.selectedCountry == nil)

            Button(String(localized: "Skip for now")) {
                onComplete()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.40))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 48)
        .background(
            LinearGradient(
                colors: [.clear, Color.deepNavy.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - TrailingIconLabelStyle

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - Preview

#if DEBUG
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Country.self, configurations: config)
    for code in ["IT", "GB", "US", "JP", "DE"] {
        container.mainContext.insert(
            Country(code: code, voltage: "230V", frequency: "50Hz", flagUnicode: "🏳️")
        )
    }
    let homeVM = HomeCountryViewModel(
        store: UserDefaultsHomeCountryStore(),
        modelContext: container.mainContext
    )
    let vm = OnboardingViewModel(modelContext: container.mainContext)
    return ZStack {
        OnboardingBackground().ignoresSafeArea()
        OnboardingPickerView(viewModel: vm, onComplete: {})
    }
    .environment(homeVM)
}
#endif
