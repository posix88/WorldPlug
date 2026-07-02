import Foundation
import SwiftUI

enum WidgetStrings {
    static func text(_ key: String) -> Text {
        Text(string(key))
    }

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main)
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let format = string(key)
        return String(format: format, locale: Locale.autoupdatingCurrent, arguments: arguments)
    }
}
