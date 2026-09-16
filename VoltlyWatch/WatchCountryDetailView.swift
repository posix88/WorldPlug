import Repository
import SwiftUI

// MARK: - WatchCountryDetailView

struct WatchCountryDetailView: View {
    let country: CountrySnapshot
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    @State private var isSaveLimitPresented = false

    var body: some View {
        List {
            WatchCountryIdentitySection(flagUnicode: country.flagUnicode, name: country.name)
            WatchPlugTypesSection(plugTypeIDs: country.plugTypeIDs)
            WatchPowerSection(voltage: country.voltage, frequency: country.frequency)
            WatchCountryActionsSection(
                countryCode: country.code,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement,
                isSaveLimitPresented: $isSaveLimitPresented
            )
        }
        .navigationTitle(country.name)
        .alert("watch.saved.limit.title", isPresented: $isSaveLimitPresented) {
            Button("watch.action.ok", role: .cancel) {}
        } message: {
            Text("watch.saved.limit.message")
        }
    }
}

// MARK: - WatchCountryIdentitySection

private struct WatchCountryIdentitySection: View {
    let flagUnicode: String
    let name: String

    var body: some View {
        Section {
            HStack {
                Text(flagUnicode)
                    .font(.title2)
                Text(name)
            }
        }
    }
}

// MARK: - WatchPlugTypesSection

private struct WatchPlugTypesSection: View {
    let plugTypeIDs: [String]

    var body: some View {
        Section {
            ForEach(plugTypeIDs, id: \.self) { plugType in
                Label {
                    Text("watch.plug.type \(plugType)", comment: "Plug type identifier.")
                } icon: {
                    WatchPlugTypeSymbol(plugTypeID: plugType)
                }
            }
        } header: {
            Text("watch.country.plug.types")
        }
    }
}

// MARK: - WatchPlugTypeSymbol

private struct WatchPlugTypeSymbol: View {
    let plugTypeID: String

    var body: some View {
        switch PlugType(rawValue: plugTypeID) {
        case .some(.unknown), .none:
            Image(systemName: "questionmark.app.fill")
        case .some:
            Image(systemName: "poweroutlet.type.\(plugTypeID.lowercased())")
        }
    }
}

// MARK: - WatchPowerSection

private struct WatchPowerSection: View {
    let voltage: String
    let frequency: String

    var body: some View {
        Section {
            LabeledContent {
                Text(voltage)
            } label: {
                Text("watch.country.voltage")
            }
            LabeledContent {
                Text(frequency)
            } label: {
                Text("watch.country.frequency")
            }
        } header: {
            Text("watch.country.power")
        }
    }
}

// MARK: - WatchCountryActionsSection

private struct WatchCountryActionsSection: View {
    let countryCode: String
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    @Binding var isSaveLimitPresented: Bool

    var body: some View {
        Section {
            WatchHomeCountryAction(countryCode: countryCode, preferencesStore: preferencesStore)
            WatchSavedCountryAction(
                countryCode: countryCode,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement,
                isSaveLimitPresented: $isSaveLimitPresented
            )
        } header: {
            Text("watch.country.actions")
        }
    }
}

// MARK: - WatchHomeCountryAction

private struct WatchHomeCountryAction: View {
    let countryCode: String
    let preferencesStore: WatchTravelPreferencesStore

    var body: some View {
        let isHome = countryCode == preferencesStore.homeCountryCode

        Button(role: isHome ? .destructive : nil) {
            if isHome {
                preferencesStore.clearHome()
            } else {
                preferencesStore.setHome(countryCode: countryCode)
            }
        } label: {
            Text(isHome ? WatchActionTitles.removeHome : WatchActionTitles.setHome)
        }
    }
}

// MARK: - WatchSavedCountryAction

private struct WatchSavedCountryAction: View {
    let countryCode: String
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    @Binding var isSaveLimitPresented: Bool

    var body: some View {
        let isSaved = preferencesStore.isSaved(countryCode: countryCode)

        Button {
            guard isSaved
                || premiumEntitlement.isPremium
                || preferencesStore.savedCountryCodes.count < 3 else {
                isSaveLimitPresented = true
                return
            }

            preferencesStore.toggleSaved(countryCode: countryCode)
        } label: {
            Text(isSaved ? WatchActionTitles.removeSaved : WatchActionTitles.saveCountry)
        }
    }
}

// MARK: - WatchActionTitles

enum WatchActionTitles {
    static let removeHome = LocalizedStringResource("watch.home.remove")
    static let setHome = LocalizedStringResource("watch.home.set")
    static let removeSaved = LocalizedStringResource("watch.saved.remove")
    static let saveCountry = LocalizedStringResource("watch.saved.add")
}

#Preview("Country Detail") {
    NavigationStack {
        WatchCountryDetailView(
            country: WatchPreviewFixtures.italy,
            preferencesStore: WatchPreviewFixtures.preferences(),
            premiumEntitlement: WatchPreviewFixtures.premium()
        )
    }
}
