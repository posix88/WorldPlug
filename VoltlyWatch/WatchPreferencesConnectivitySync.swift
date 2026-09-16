import Foundation
import Repository
import WatchConnectivity

// MARK: - WatchPreferencesConnectivitySync

/// Receives the latest paired-iPhone preferences while iCloud finishes its first sync.
final class WatchPreferencesConnectivitySync: NSObject, WCSessionDelegate {
    private let session: WCSession
    private let receivePreferences: @MainActor @Sendable (TravelPreferences) -> Void

    init(receivePreferences: @escaping @MainActor @Sendable (TravelPreferences) -> Void) {
        self.session = .default
        self.receivePreferences = receivePreferences
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
        receivePreferencesIfAvailable(from: session.receivedApplicationContext)
    }

    func publish(_ preferences: TravelPreferences) {
        guard session.activationState == .activated else {
            return
        }

        let context = TravelPreferencesWatchTransfer.applicationContext(for: preferences)
        guard !context.isEmpty else {
            return
        }

        try? session.updateApplicationContext(context)
    }

    private func receivePreferencesIfAvailable(from applicationContext: [String: Any]) {
        guard let preferences = TravelPreferencesWatchTransfer.preferences(from: applicationContext) else {
            return
        }

        Task { @MainActor [receivePreferences] in
            receivePreferences(preferences)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else {
            return
        }

        receivePreferencesIfAvailable(from: session.receivedApplicationContext)
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        receivePreferencesIfAvailable(from: applicationContext)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}
