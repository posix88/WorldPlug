import SwiftUI

// MARK: - OnboardingBackground

struct OnboardingBackground: View {
    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .deepCosmos, .deepNavy,   .deepCosmos,
                .deepPurple, .electricPulse, .deepIndigo,
                .deepSpace,  .deepViolet, .deepSpace
            ]
        )
    }
}
