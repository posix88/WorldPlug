//
//  Utilities.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 10/04/24.
//

import SwiftUI
import Repository_iOS

public extension View {
    @ViewBuilder
    /// Embed the current View in a `Card` style background.
    /// - Parameter color: the background color
    /// - Parameter radius: the card corner radius
    /// - Parameter insets: the insets to be applied to the card view content
    /// - Parameter borderColor: the card border color
    /// - Parameter border: the card border tickness
    func embedInCard(
        _ color: Color = WorldPlugAsset.Assets.card.swiftUIColor,
        radius: CGFloat = 10,
        insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
        borderColor: Color = WorldPlugAsset.Assets.border.swiftUIColor,
        border: CGFloat = 1,
        action: (() -> Void)? = nil
    ) -> some View {
        padding(insets)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: border)
                    .fill(color)
            }
            .contentShape(RoundedRectangle(cornerRadius: radius))
    }

    /// Sets a clipping shape with rounded corners for this view.
    /// - Parameters:
    ///   - radius: the corner radius
    func roundedCorner(radius: CGFloat) -> some View {
        clipped()
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    /// Sets a clipping shape with rounded corners for this view, tracing the outline of this shape with a color.
    /// - Parameters:
    ///   - radius: the corner radius
    ///   - lineWidth: the outline width
    ///   - borderColor: the outline color
    func roundedCornerWithBorder(
        radius: CGFloat,
        lineWidth: CGFloat = 0,
        borderColor: Color = .clear
    ) -> some View {
        roundedCorner(radius: radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: lineWidth)
            )
    }
}

extension Plug {
    var plugSymbol: String {
        switch plugType {
        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o:
            "poweroutlet.type.\(plugType.rawValue.lowercased())"

        case .unknown:
            "questionmark.app.fill"
        }
    }
}


public extension View {
    @ViewBuilder
    /// A View modifier that allows to retrieve the current view size
    func viewSizeReader(_ size: Binding<CGSize>) -> some View {
        modifier(ViewSizeReaderViewModifier(viewSize: size))
    }
}

// MARK: - ViewSizeReaderViewModifier

private struct ViewSizeReaderViewModifier: ViewModifier {
    @Binding var viewSize: CGSize

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader {
                    Color.clear.preference(key: ViewSizeKey.self, value: $0.frame(in: .local).size)
                }
            )
            .onPreferenceChange(ViewSizeKey.self) {
                viewSize = $0
            }
    }
}

// MARK: - ViewSizeKey

/// Preference key used to let the view size propagate to the caller
private struct ViewSizeKey: SwiftUI.PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout Value, nextValue: () -> Value) {}
}
