import Analytics
import AppIntents
import Repository
import SwiftUI

// MARK: - CountryDestinationPickerView

/// One searchable country picker, used by the trip editor (pick a destination) and by Settings
/// (pick a home country, pick the favorite-widget country). The differences between those three
/// are the title, the analytics screen, whether "None" is offered, and which countries are on
/// offer — all parameters, so there is no reason for a second picker to exist.
struct CountryDestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Binding var selectedCountryCode: String
    @State private var viewModel: CountryDestinationPickerViewModel
    private let title: String
    private let screen: AnalyticsScreen
    /// When true, an empty `selectedCountryCode` is a valid state and a "None" row is offered.
    private let allowsNoSelection: Bool
    private let noSelectionTitle: String

    init(
        selectedCountryCode: Binding<String>,
        countries: [Country],
        title: String = LocalizationKeys.tripDestination.localized,
        screen: AnalyticsScreen = .tripDestination,
        allowsNoSelection: Bool = false,
        noSelectionTitle: String = LocalizationKeys.favoriteWidgetNoSelection.localized
    ) {
        _selectedCountryCode = selectedCountryCode
        _viewModel = State(initialValue: CountryDestinationPickerViewModel(countries: countries))
        self.title = title
        self.screen = screen
        self.allowsNoSelection = allowsNoSelection
        self.noSelectionTitle = noSelectionTitle
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            if allowsNoSelection {
                noSelectionRow
            }

            ForEach(viewModel.filteredCountries(locale: locale)) { country in
                countryRow(country)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { AppMeshBackground() }
        .navigationTitle(title)
        .onAppear {
            analyticsTracker.screen(screen)
        }
        .tint(.voltTint)
        .searchable(
            text: $viewModel.searchQuery,
            prompt: Text(LocalizationKeys.tripSearchDestination.localized)
        )
    }

    private var noSelectionRow: some View {
        Button {
            selectedCountryCode = ""
            dismiss()
        } label: {
            HStack(spacing: .md) {
                Text(noSelectionTitle)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedCountryCode.isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityLabel(noSelectionTitle)
        .accessibilityAddTraits(selectedCountryCode.isEmpty ? .isSelected : [])
    }

    private func countryRow(_ country: Country) -> some View {
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
        .appEntityIdentifier(
            EntityIdentifier(for: CountryEntity.self, identifier: country.code)
        )
    }
}

#if DEBUG
#Preview("Destination") {
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

#Preview("With a None option") {
    NavigationStack {
        CountryDestinationPickerView(
            selectedCountryCode: .constant(""),
            countries: [
                Country(code: "IT", voltage: "230V", frequency: "50Hz", flagUnicode: "🇮🇹"),
                Country(code: "JP", voltage: "100V", frequency: "50/60Hz", flagUnicode: "🇯🇵")
            ],
            title: LocalizationKeys.favoriteWidgetTitle.localized,
            screen: .settings,
            allowsNoSelection: true
        )
    }
    .environment(\.analyticsTracker, NoopAnalyticsTracker())
}
#endif
