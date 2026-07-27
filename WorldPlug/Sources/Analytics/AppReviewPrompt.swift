import Foundation

@MainActor
enum AppReviewPrompt {
    private static let hasRequestedKey = "app.review.prompt.has.requested"

    static func requestAfterSuccessfulAction(using requestReview: () -> Void) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: hasRequestedKey) else {
            return
        }

        defaults.set(true, forKey: hasRequestedKey)
        requestReview()
    }
}
