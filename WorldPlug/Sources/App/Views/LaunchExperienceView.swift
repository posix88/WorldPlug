import SwiftUI

// MARK: - LaunchExperienceView

// MARK: - LaunchExperienceView

struct LaunchExperienceView: View {
    /// Whether startup work the rest of the app depends on (currently: StoreKit entitlement
    /// refresh) has finished. The splash won't dismiss before both this is `true` *and* the
    /// minimum splash duration has elapsed — see `AppCoordinator.hasRefreshedEntitlements`.
    let isReady: Bool
    let dismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false
    @State private var hasMetMinimumDuration = false
    @State private var hasDismissed = false
    @State private var socketSymbolName = Self.socketSymbols.randomElement() ?? "poweroutlet.type.c.fill"

    var body: some View {
        ZStack {
            Color.backgroundSurface
                .ignoresSafeArea()
            Image(systemName: socketSymbolName)
                .font(.system(size: 58, weight: .medium))
                .foregroundStyle(.backgroundSurface)
                .padding(38)
                .background(.voltTint, in: Circle())
                .shadow(color: .voltTint.opacity(0.28), radius: 28, y: 12)
                .scaleEffect(isPresented ? 1 : 0.82)
                .opacity(isPresented ? 1 : 0)
        }
        .accessibilityHidden(true)
        .task {
            if reduceMotion {
                isPresented = true
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.18)) {
                    isPresented = true
                }
            }

            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else {
                return
            }

            hasMetMinimumDuration = true
            dismissIfReady()

            // Safety net: startup work (StoreKit, in practice) is almost always fast/local, but
            // this guarantees the splash can never hang indefinitely if it isn't.
            try? await Task.sleep(for: .milliseconds(2450))
            guard !Task.isCancelled else {
                return
            }

            dismissNow()
        }
        .onChange(of: isReady) { _, _ in
            dismissIfReady()
        }
    }

    private func dismissIfReady() {
        guard hasMetMinimumDuration, isReady else {
            return
        }

        dismissNow()
    }

    private func dismissNow() {
        guard !hasDismissed else {
            return
        }

        hasDismissed = true
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.28)) {
            dismiss()
        }
    }

    private static let socketSymbols = [
        "poweroutlet.type.a.fill",
        "poweroutlet.type.b.fill",
        "poweroutlet.type.c.fill",
        "poweroutlet.type.d.fill",
        "poweroutlet.type.e.fill",
        "poweroutlet.type.f.fill",
        "poweroutlet.type.g.fill",
        "poweroutlet.type.h.fill",
        "poweroutlet.type.i.fill",
        "poweroutlet.type.j.fill",
        "poweroutlet.type.k.fill",
        "poweroutlet.type.l.fill",
        "poweroutlet.type.m.fill",
        "poweroutlet.type.n.fill",
        "poweroutlet.type.o.fill"
    ]
}

#Preview("Light") {
    LaunchExperienceView(isReady: true, dismiss: {})
}

#Preview("Dark") {
    LaunchExperienceView(isReady: true, dismiss: {})
        .preferredColorScheme(.dark)
}
