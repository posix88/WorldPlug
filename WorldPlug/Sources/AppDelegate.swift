import Analytics
import Foundation
import Repository
import TipKit
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseAnalyticsTracker.configure()
        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
        return true
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Repository.preloadData()
        return true
    }
}
