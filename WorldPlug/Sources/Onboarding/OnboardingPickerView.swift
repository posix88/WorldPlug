import Repository
import SwiftUI

// MARK: - OnboardingPickerView

struct OnboardingPickerView<ViewModel: OnboardingViewModelType>: View {
    @Environment(\.homeCountryViewModel) private var homeViewModel
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: ViewModel
    @FocusState private var searchFocused: Bool
    @State private var isSearching: Bool = false
    @ScaledMetric(relativeTo: .title) private var homeIconSize: CGFloat = 36
    let onComplete: () -> Void

    var body: some View {
        let countries = viewModel.countries(for: locale)

        VStack(spacing: 0) {
            // Header — collapses when keyboard is active to free up space
            if !isSearching {
                VStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: homeIconSize, weight: .bold))
                        .foregroundStyle(.yellow)
                        .padding(.top, .special)
                        .symbolEffect(.bounce, options: .nonRepeating, isActive: !reduceMotion)

                    Text(LocalizationKeys.onboardingPickerTitle.localized)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)

                    Text(LocalizationKeys.onboardingPickerSubtitle.localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .xxxl)
                .padding(.bottom, .xxl)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Search bar — always visible
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.45))

                TextField(
                    text: $viewModel.searchQuery,
                    prompt: Text(LocalizationKeys.onboardingSearchPlaceholder.localized)
                        .foregroundStyle(.white.opacity(0.45))
                ) { EmptyView() }
                    .foregroundStyle(.white)
                    .tint(.yellow)
                    .submitLabel(.search)
                    .focused($searchFocused)

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
            .padding(.vertical, .lg)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, .xxxl)
            .padding(.bottom, .md)

            // Country list — only this region scrolls
            ScrollView {
                LazyVStack(spacing: .sm) {
                    ForEach(countries) { country in
                        OnboardingCountryRow(
                            country: country,
                            isSelected: viewModel.selectedCountry?.code == country.code
                        ) {
                            withMotionAwareAnimation(
                                .spring(response: 0.3, dampingFraction: 0.75),
                                reduceMotion: reduceMotion
                            ) {
                                let alreadySelected = viewModel.selectedCountry?.code == country.code
                                viewModel.selectedCountry = alreadySelected ? nil : country
                            }
                        }
                    }
                }
                .padding(.horizontal, .xxxl)
                .padding(.vertical, .md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: searchFocused) { _, focused in
            withMotionAwareAnimation(
                .spring(response: 0.35, dampingFraction: 0.85),
                reduceMotion: reduceMotion
            ) {
                isSearching = focused
            }
        }
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
                            "\(selected.flagUnicode)  \(selected.localizedName(in: locale))",
                            systemImage: "arrow.right"
                        )
                        .labelStyle(TrailingIconLabelStyle())
                    } else {
                        Text(LocalizationKeys.onboardingSelectCountry.localized)
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
                .animation(
                    reduceMotion ? nil : .spring(response: 0.4),
                    value: viewModel.selectedCountry?.code
                )
            }
            .disabled(viewModel.selectedCountry == nil)
        }
        .padding(.horizontal, .xxxl)
        .padding(.top, .lg)
        .padding(.bottom, .lg)
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
        HStack(spacing: .md) {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let countries = ["IT", "GB", "US", "JP", "DE"].map {
        Country(code: $0, voltage: "230V", frequency: "50Hz", flagUnicode: "🏳️")
    }
    let vm = PreviewOnboardingViewModel(countries: countries)
    return ZStack {
        OnboardingBackground().ignoresSafeArea()
        OnboardingPickerView(viewModel: vm, onComplete: {})
    }
    .environment(\.homeCountryViewModel, PreviewHomeCountryViewModel())
}
#endif
