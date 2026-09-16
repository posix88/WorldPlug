import Repository
import SwiftUI

// MARK: - WatchCountryNavigationLink

struct WatchCountryNavigationLink: View {
    let country: CountrySnapshot
    let preferencesStore: WatchTravelPreferencesStore
    let premiumEntitlement: WatchPremiumEntitlement
    @State private var isSaveLimitPresented = false

    var body: some View {
        let isHome = country.code == preferencesStore.homeCountryCode
        let isSaved = preferencesStore.isSaved(countryCode: country.code)

        NavigationLink {
            WatchCountryDetailView(
                country: country,
                preferencesStore: preferencesStore,
                premiumEntitlement: premiumEntitlement
            )
        } label: {
            WatchCountryRow(
                flagUnicode: country.flagUnicode,
                name: country.name,
                isHome: isHome,
                isSaved: isSaved
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            homeAction(isHome: isHome)
            savedAction(isSaved: isSaved)
        }
        .alert("watch.saved.limit.title", isPresented: $isSaveLimitPresented) {
            Button("watch.action.ok", role: .cancel) {}
        } message: {
            Text("watch.saved.limit.message")
        }
    }

    private func homeAction(isHome: Bool) -> some View {
        // A destructive swipe action makes `List` optimistically remove its row. Clearing home
        // changes only the country badge, so retain the row and use the red tint for its warning.
        Button {
            if isHome {
                preferencesStore.clearHome()
            } else {
                preferencesStore.setHome(countryCode: country.code)
            }
        } label: {
            Label {
                Text(isHome ? WatchActionTitles.removeHome : WatchActionTitles.setHome)
            } icon: {
                Image(systemName: "house")
            }
        }
        .tint(isHome ? .red : .blue)
    }

    private func savedAction(isSaved: Bool) -> some View {
        // Removing a saved status must likewise keep this row in the all-countries list.
        Button {
            guard isSaved
                || premiumEntitlement.isPremium
                || preferencesStore.savedCountryCodes.count < 3 else {
                isSaveLimitPresented = true
                return
            }

            preferencesStore.toggleSaved(countryCode: country.code)
        } label: {
            Label {
                Text(isSaved ? WatchActionTitles.removeSaved : WatchActionTitles.saveCountry)
            } icon: {
                Image(systemName: "star")
            }
        }
        .tint(isSaved ? .red : .green)
    }
}

#Preview("Country Navigation") {
    NavigationStack {
        List {
            WatchCountryNavigationLink(
                country: WatchPreviewFixtures.italy,
                preferencesStore: WatchPreviewFixtures.preferences(),
                premiumEntitlement: WatchPreviewFixtures.premium()
            )
        }
    }
}
