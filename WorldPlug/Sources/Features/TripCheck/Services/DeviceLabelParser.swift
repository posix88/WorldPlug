import Foundation

// MARK: - DeviceLabelValues

struct DeviceLabelValues: Equatable, Sendable {
    let voltage: String
    let frequency: String
}

// MARK: - DeviceLabelParser

enum DeviceLabelParser {
    static func values(in text: String) -> DeviceLabelValues {
        let normalized = text.replacingOccurrences(of: "–", with: "-")
        return DeviceLabelValues(
            voltage: firstMatch(
                in: normalized,
                pattern: #"\b\d{2,3}\s*(?:-|to|/)\s*\d{2,3}\s*V(?:AC)?\b|\b\d{2,3}\s*V(?:AC)?\b"#
            ),
            frequency: firstMatch(
                in: normalized,
                pattern: #"\b(?:\d{2}\s*(?:/|-)\s*\d{2}|\d{2})\s*Hz\b"#
            )
        )
    }

    private static func firstMatch(in text: String, pattern: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return ""
        }

        return String(text[range])
    }
}
