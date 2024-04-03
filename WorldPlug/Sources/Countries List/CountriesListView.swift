import SwiftUI
import ComposableArchitecture

public struct CountriesListView: View {
    let store: StoreOf<CountriesListFeature>

    public var body: some View {
        List {
            ForEach(store.countries) { country in
                HStack {
                    Text(country.flagUnicode)
                    Text(country.localizedName)
                }
            }
        }
        .onAppear {
            store.send(.loadView)
        }
    }
}


#Preview {
    CountriesListView(
        store: Store(initialState: CountriesListFeature.State()) {
            CountriesListFeature()
        }
    )
}
