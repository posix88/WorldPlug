import Repository
import SwiftData
import SwiftUI
import TipKit

// MARK: - SavedCountriesView

struct SavedCountriesView: View {
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @Environment(\.locale) private var locale
    @Query(sort: \Country.code) private var countries: [Country]
    @State private var isTripEditorPresented = false
    @State private var selectedCountry: Country?
    private let nextTripTip = NextTripTip()
    private let favoriteWidgetSelectorTip = FavoriteWidgetSelectorTip()

    var body: some View {
        NavigationStack {
            Group {
                if premiumEntitlement.isPremium {
                    ScrollView {
                        LazyVStack(spacing: .md) {
                            nextTripCard
                            favoriteWidgetCard

                            if savedCountries.isEmpty {
                                ContentUnavailableView(
                                    LocalizationKeys.savedCountriesEmptyTitle.localized,
                                    systemImage: "star",
                                    description: Text(LocalizationKeys.savedCountriesEmptyDescription.localized)
                                )
                                .padding(.top, .special)
                            } else {
                                ForEach(savedCountries) { country in
                                    CountryBrowserRow(
                                        country: country,
                                        compatibility: nil,
                                        selection: $selectedCountry
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, .xxl)
                        .padding(.vertical, .md)
                    }
                    .navigationDestination(item: $selectedCountry) { country in
                        CountryDetailView(country: country)
                    }
                } else {
                    ContentUnavailableView(
                        LocalizationKeys.savedCountriesPremiumTitle.localized,
                        systemImage: "lock.fill",
                        description: Text(LocalizationKeys.savedCountriesPremiumDescription.localized)
                    )
                }
            }
            .navigationTitle(LocalizationKeys.savedCountriesTitle.localized)
            .toolbar {
                if premiumEntitlement.isPremium {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isTripEditorPresented = true
                            nextTripTip.invalidate(reason: .actionPerformed)
                        } label: {
                            Image(systemName: travelPreferencesStore.preferences.nextTrip == nil ? "calendar.badge.plus" : "calendar")
                        }
                        .accessibilityLabel(LocalizationKeys.nextTripEdit.localized)
                        .popoverTip(nextTripTip, arrowEdge: .top)
                        .appTipIconTint()
                    }
                }
            }
            .background { AppMeshBackground() }
            .sheet(isPresented: $isTripEditorPresented) {
                NextTripEditorView(
                    trip: travelPreferencesStore.preferences.nextTrip,
                    countries: countries,
                    onSave: { trip in
                        travelPreferencesStore.setNextTrip(trip)
                    },
                    onDelete: {
                        travelPreferencesStore.setNextTrip(nil)
                    }
                )
            }
        }
    }

    private var savedCountries: [Country] {
        let countriesByCode = Dictionary(uniqueKeysWithValues: countries.map { ($0.code, $0) })
        return travelPreferencesStore.preferences.savedCountryCodes.compactMap { countriesByCode[$0] }
    }

    @ViewBuilder
    private var nextTripCard: some View {
        if let trip = travelPreferencesStore.preferences.nextTrip,
           let country = countries.first(where: { $0.code == trip.countryCode }) {
            Button {
                isTripEditorPresented = true
            } label: {
                VStack(alignment: .leading, spacing: .sm) {
                    Text(LocalizationKeys.nextTripTitle.localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textLight)
                        .textCase(.uppercase)

                    Text(trip.name ?? "\(country.flagUnicode) \(country.localizedName(in: locale))")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(trip.departureDate, format: .dateTime.day().month().year())
                        .font(.subheadline)
                        .foregroundStyle(.textLight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.lg)
                .background(.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var favoriteWidgetCard: some View {
        Menu {
            Button(LocalizationKeys.favoriteWidgetNoSelection.localized) {
                travelPreferencesStore.setFavoriteWidgetCountry(code: nil)
                favoriteWidgetSelectorTip.invalidate(reason: .actionPerformed)
            }

            ForEach(savedCountries) { country in
                Button("\(country.flagUnicode) \(country.localizedName(in: locale))") {
                    travelPreferencesStore.setFavoriteWidgetCountry(code: country.code)
                    favoriteWidgetSelectorTip.invalidate(reason: .actionPerformed)
                }
            }
        } label: {
            HStack(spacing: .md) {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: .xxs) {
                    Text(LocalizationKeys.favoriteWidgetTitle.localized)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.textRegular)

                    Text(favoriteWidgetCountryName)
                        .font(.caption)
                        .foregroundStyle(.textLight)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.textLighter)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.lg)
            .background(.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(savedCountries.isEmpty)
        .popoverTip(savedCountries.isEmpty ? nil : favoriteWidgetSelectorTip, arrowEdge: .bottom)
        .appTipIconTint()
        .accessibilityLabel(LocalizationKeys.favoriteWidgetTitle.localized)
        .accessibilityValue(favoriteWidgetCountryName)
    }

    private var favoriteWidgetCountryName: String {
        guard let countryCode = travelPreferencesStore.preferences.favoriteWidgetCountryCode,
              let country = countries.first(where: { $0.code == countryCode }) else {
            return LocalizationKeys.favoriteWidgetNoSelection.localized
        }

        return "\(country.flagUnicode) \(country.localizedName(in: locale))"
    }
}

// MARK: - Tips

private struct NextTripTip: Tip {
    var title: Text {
        Text(LocalizationKeys.nextTripTipTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.nextTripTipMessage.localized)
    }

    var image: Image? {
        Image(systemName: "calendar.badge.plus")
    }
}

private struct FavoriteWidgetSelectorTip: Tip {
    var title: Text {
        Text(LocalizationKeys.favoriteWidgetTipTitle.localized)
    }

    var message: Text? {
        Text(LocalizationKeys.favoriteWidgetTipMessage.localized)
    }

    var image: Image? {
        Image(systemName: "rectangle.on.rectangle")
    }
}

#if DEBUG
#Preview {
    SavedCountriesView()
}
#endif
