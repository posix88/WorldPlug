import SwiftUI

// MARK: - AppMeshBackground

struct AppMeshBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .deepCosmos, .deepNavy, .deepCosmos,
                        .deepPurple, .electricPulse.opacity(0.45), .deepIndigo,
                        .deepSpace, .deepViolet, .deepSpace
                    ]
                )
            } else {
                Color.backgroundSurface
            }
        }
        .ignoresSafeArea()
    }
}
