import SwiftUI
import WidgetKit

struct WidgetFlag: View {
    let flagUnicode: String
    let pointSize: CGFloat

    var body: some View {
        if let image {
            Image(uiImage: image)
                .widgetAccentedRenderingMode(.fullColor)
        } else {
            Text(flagUnicode)
                .font(.system(size: pointSize))
        }
    }

    private var image: UIImage? {
        let renderer = ImageRenderer(
            content: Text(flagUnicode)
                .font(.system(size: pointSize))
        )
        renderer.scale = 3
        return renderer.uiImage
    }
}
