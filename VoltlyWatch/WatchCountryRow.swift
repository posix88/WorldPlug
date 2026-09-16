import SwiftUI

// MARK: - WatchCountryRow

struct WatchCountryRow: View {
    let flagUnicode: String
    let name: String
    let isHome: Bool
    let isSaved: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(flagUnicode)
            Text(name)
                .lineLimit(1)
            Spacer(minLength: 4)
            if isHome {
                Image(systemName: "house.fill")
                    .foregroundStyle(.tint)
            }
            if isSaved {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

#Preview("Country Row") {
    List {
        WatchCountryRow(
            flagUnicode: WatchPreviewFixtures.italy.flagUnicode,
            name: WatchPreviewFixtures.italy.name,
            isHome: true,
            isSaved: true
        )
    }
}
