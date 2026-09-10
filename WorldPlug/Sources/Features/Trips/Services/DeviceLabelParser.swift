import Foundation

// MARK: - DeviceLabelValues

struct DeviceLabelValues: Codable, Equatable, Sendable {
    let voltage: String
    let frequency: String
}

// MARK: - DeviceLabelParser

enum DeviceLabelParser {
    static func values(in text: String) -> DeviceLabelValues {
        let normalized = text.replacingOccurrences(of: "–", with: "-")
        return DeviceLabelValues(
            // `\b` requires a transition between a word character and a non-word character, but
            // digits and letters are both word characters — so `\b` never matches between them,
            // and a label with no space before the rating (e.g. "AC100-240V", extremely common on
            // real power-adapter labels) would never match. `(?<!\d)` instead only forbids the
            // digits being preceded by *another* digit, so "AC100V"/"AC100-240V" match correctly
            // while still not matching the middle of a longer, unrelated digit run.
            voltage: firstMatch(
                in: normalized,
                pattern: #"(?<!\d)\d{2,3}\s*(?:-|to|/)\s*\d{2,3}\s*V(?:AC)?\b|(?<!\d)\d{2,3}\s*V(?:AC)?\b"#
            ),
            frequency: firstMatch(
                in: normalized,
                pattern: #"(?<!\d)(?:\d{2,3}\s*(?:/|-)\s*\d{2,3}|\d{2,3})\s*Hz\b"#
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
