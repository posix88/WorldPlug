import Analytics
import Repository
import SwiftUI

// MARK: - CountryDestinationPickerView

struct CountryDestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Binding var selectedCountryCode: String
    @State private var viewModel: CountryDestinationPickerViewModel

    init(selectedCountryCode: Binding<String>, countries: [Country]) {
        _selectedCountryCode = selectedCountryCode
        _viewModel = State(initialValue: CountryDestinationPickerViewModel(countries: countries))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List(viewModel.filteredCountries(locale: locale)) { country in
            Button {
                selectedCountryCode = country.code
                dismiss()
            } label: {
                HStack(spacing: .md) {
                    Text(country.flagUnicode)

                    Text(country.localizedName(in: locale))
                        .foregroundStyle(.primary)

                    Spacer()

                    if country.code == selectedCountryCode {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityLabel(country.localizedName(in: locale))
            .accessibilityAddTraits(country.code == selectedCountryCode ? .isSelected : [])
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { AppMeshBackground() }
        .navigationTitle(LocalizationKeys.nextTripDestination.localized)
        .onAppear {
            analyticsTracker.screen(.nextTripDestination)
        }
        .tint(.voltTint)
        .searchable(
            text: $viewModel.searchQuery,
            prompt: Text(LocalizationKeys.nextTripSearchDestination.localized)
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CountryDestinationPickerView(
            selectedCountryCode: .constant("JP"),
            countries: [
                Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹"),
                Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
            ]
        )
    }
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
