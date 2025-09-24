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
    private let shadow: ShadowStyle
    private let content: () -> Content

    /// Initializes a new instance of `Card` with enhanced styling options.
    ///
    /// - Parameters:
    ///   - background: The background color of the card (default is `.cardSurface`).
    ///   - radius: The corner radius of the card (default is 12 for more modern look).
    ///   - insets: The padding inside the card (default is 20 points for better spacing).
    ///   - spacing: The spacing for the content inside the card (default is 0).
    ///   - borderColor: The color of the card's border (default is `.borderStroke`).
    ///   - border: The width of the card's border (default is 0.5 for subtle border).
    ///   - shadow: The shadow style for the card (default is `.subtle`).
    ///   - content: A closure that returns the content to display inside the card.
    init(
        background: Color = .cardSurface,
        radius: CGFloat = 12,
        insets: EdgeInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20),
        spacing: CGFloat = .zero,
        borderColor: Color = .borderStroke,
        border: CGFloat = 0.5,
        dashed: Bool = false,
        shadow: ShadowStyle = .subtle,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.background = background
        self.radius = radius
        self.insets = insets
        self.spacing = spacing
        self.borderColor = borderColor
        self.border = border
        self.dashed = dashed
        self.shadow = shadow
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
        .applyShadow(shadow)
    }
}

/// Shadow styles for enhanced card appearance
///
/// Provides predefined shadow styles for cards and other UI components, ranging from no shadow
/// to strong shadows, plus a custom option for complete control over shadow appearance.
enum ShadowStyle {
    /// No shadow applied to the view.
    ///
    /// Use this for a flat design or when shadows are not desired.
    case none
    
    /// A subtle shadow with minimal visual impact.
    ///
    /// Creates a light shadow with 8% black opacity, 8pt radius, and 2pt vertical offset.
    /// Ideal for cards that need slight depth without being too prominent.
    case subtle
    
    /// A medium shadow with moderate visual impact.
    ///
    /// Creates a noticeable shadow with 12% black opacity, 12pt radius, and 4pt vertical offset.
    /// Good for components that need more pronounced depth and separation from the background.
    case medium
    
    /// A strong shadow with significant visual impact.
    ///
    /// Creates a prominent shadow with 16% black opacity, 16pt radius, and 6pt vertical offset.
    /// Best for modals, overlays, or components that need strong emphasis and elevation.
    case strong
    
    /// A custom shadow with full control over all shadow properties.
    ///
    /// - Parameters:
    ///   - color: The color of the shadow
    ///   - radius: The blur radius of the shadow
    ///   - x: The horizontal offset of the shadow
    ///   - y: The vertical offset of the shadow
    ///
    /// Use this when the predefined shadow styles don't meet your specific design requirements.
    case custom(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
}

/// Extension to apply shadow styles
extension View {
    @ViewBuilder
    func applyShadow(_ style: ShadowStyle) -> some View {
        switch style {
        case .none:
            self
        case .subtle:
            self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        case .medium:
            self.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        case .strong:
            self.shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 6)
        case .custom(let color, let radius, let x, let y):
            self.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}
