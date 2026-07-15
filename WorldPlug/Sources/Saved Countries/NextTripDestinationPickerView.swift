import Analytics
import Repository
import SwiftUI

// MARK: - NextTripDestinationPickerView

struct NextTripDestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Binding var selectedCountryCode: String
    @State private var searchQuery = ""

    let countries: [Country]

    var body: some View {
        List(filteredCountries) { country in
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
            .accessibilityLabel(country.localizedName(in: locale))
            .accessibilityAddTraits(country.code == selectedCountryCode ? .isSelected : [])
        }
        .navigationTitle(LocalizationKeys.nextTripDestination.localized)
        .onAppear {
            analyticsTracker.screen(.nextTripDestination)
        }
        .tint(.yellow)
        .searchable(
            text: $searchQuery,
            prompt: Text(LocalizationKeys.nextTripSearchDestination.localized)
        )
    }

    private var filteredCountries: [Country] {
        countries
            .filter {
                searchQuery.isEmpty ||
            $0.localizedName(in: locale).localizedCaseInsensitiveContains(searchQuery)
            }
            .sortedByLocalizedName(in: locale)
    }
}
