import SwiftUI

struct FavoriteCountryHeader: View {
    var body: some View {
        Label(WidgetStrings.string("widget.favorite.label"), systemImage: "star.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.yellow)
    }
}
