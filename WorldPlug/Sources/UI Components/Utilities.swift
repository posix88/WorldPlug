//
//  Utilities.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 10/04/24.
//

import SwiftUI

func withMotionAwareAnimation(
    _ animation: Animation,
    reduceMotion: Bool,
    _ body: () -> Void
) {
    guard !reduceMotion else {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
        return
    }

    withAnimation(animation, body)
}

extension View {
    /// Sets a clipping shape with rounded corners for this view.
    /// - Parameters:
    ///   - radius: the corner radius
    func roundedCorner(radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
