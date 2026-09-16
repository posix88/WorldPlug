import Foundation
import Repository
import WatchConnectivity

// MARK: - PhoneWatchPreferencesSync

/// Sends the latest iPhone preferences to the paired watch.
///
/// The application context is a launch-time fallback for a Watch app whose iCloud key-value
/// store has not yet finished its initial synchronization.
@MainActor
final class PhoneWatchPreferencesSync: NSObject, WCSessionDelegate {
    private let session: WCSession
    private var latestPreferences = TravelPreferences()
    private var receivePreferences: (@MainActor @Sendable (TravelPreferences) -> Void)?

    override init() {
        self.session = .default
        super.init()

    }

    func activate(
        receivePreferences: @escaping @MainActor @Sendable (TravelPreferences) -> Void
    ) {
        self.receivePreferences = receivePreferences

        guard WCSession.isSupported() else {
            return
        }

        session.delegate = self
        session.activate()
    }

    func publish(_ preferences: TravelPreferences) {
        latestPreferences = preferences
        sendLatestPreferences()
    }

    private func sendLatestPreferences() {
        guard session.activationState == .activated else {
            return
        }

        let context = TravelPreferencesWatchTransfer.applicationContext(for: latestPreferences)
        guard !context.isEmpty else {
            return
        }

        try? session.updateApplicationContext(context)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.sendLatestPreferences()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let preferences = TravelPreferencesWatchTransfer.preferences(from: applicationContext) else {
            return
        }

        Task { @MainActor [weak self] in
            self?.receivePreferences?(preferences)
        }
    }
}
