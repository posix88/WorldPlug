//
//  Card.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 18/09/25.
//

import SwiftUI

/// A custom container view that applies a background, border, and corner radius to its content.
///
/// This view is intended to be used for presenting content inside a card-like container. The container
/// has configurable options for background color, corner radius, border color, and padding (insets).
///
/// **Important Note:**
/// - This component is purely for displaying content. Any actions or closures (e.g., tap gestures) should
///   **not** be added directly here. Instead, the user should handle any actions or closures outside of
///   this component, such as by wrapping the `Card` in a `Button` or using a `Gesture` in the parent view.
///
/// - Make sure to pass the content as a closure that returns a `View`. The content can be anything from text,
///   images, or custom views.
struct Card<Content>: View where Content: View {
    private let insets: EdgeInsets
    private let background: Color
    private let radius: CGFloat
    private let spacing: CGFloat
    private let borderColor: Color
    private let border: CGFloat
    private let dashed: Bool
    private let content: () -> Content

    /// Initializes a new instance of `CardContainer`.
    ///
    /// - Parameters:
    ///   - background: The background color of the card (default is `AppTheme.space.surface.regular.swiftUIColor`).
    ///   - radius: The corner radius of the card (default is 4).
    ///   - insets: The padding inside the card (default is 16 points for all edges).
    ///   - spacing: The spacing for the content inside the card (default is 0).
    ///   - borderColor: The color of the card's border (default is `AppTheme.interface.neutral.light.swiftUIColor`).
    ///   - border: The width of the card's border (default is 1).
    ///   - content: A closure that returns the content to display inside the card.
    init(
        background: Color = .cardSurface,
        radius: CGFloat = 4,
        insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
        spacing: CGFloat = .zero,
        borderColor: Color = .borderStroke,
        border: CGFloat = 1,
        dashed: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.background = background
        self.radius = radius
        self.insets = insets
        self.spacing = spacing
        self.borderColor = borderColor
        self.border = border
        self.dashed = dashed
        self.content = content
    }

    var body: some View {
        VStack(spacing: spacing) {
            content()
        }
        .padding(insets)
        .background(background)
        .mask(
            RoundedRectangle(cornerRadius: radius)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: radius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .stroke(borderColor, style: .init(lineWidth: border, dash: dashed ? [5, 5] : []))
        }
    }
}
