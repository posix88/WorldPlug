import Foundation
import SwiftUI

/// The widget extension's own string access.
///
/// Separate from the app target's `LocalizationKeys` because the extension has its own catalog
/// (`VoltlyWidgets/Resources/Localizable.xcstrings`) and cannot see the app's.
enum WidgetStrings {
    /// A `Text` that still carries the resource, so SwiftUI resolves it at render time and the
    /// `\.locale` environment override keeps working — `Text(string(key))` would hand `Text` an
    /// already-resolved `String` and take the non-localizing `StringProtocol` overload.
    static func text(_ key: String) -> Text {
        Text(resource(key))
    }

    /// `#bundle` rather than `.main`: both resolve to the extension's own bundle from inside the
    /// extension, but `#bundle` says so explicitly and keeps working if this file is ever moved
    /// into a package or framework, where `.main` would silently start searching the host app.
    static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(key), bundle: .atURL(Bundle.main.bundleURL))
    }

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main)
    }

    /// `locale:` is what keeps numbers in the user's own numerals — `String(format:)` without it
    /// renders digits as ASCII 0-9 regardless of locale.
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: .autoupdatingCurrent, arguments: arguments)
    }
}
