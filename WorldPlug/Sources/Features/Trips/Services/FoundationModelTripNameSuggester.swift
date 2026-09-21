import Foundation
import FoundationModels

// MARK: - TripNameSuggesting

/// Generates short, personal trip titles without sending the destination anywhere.
protocol TripNameSuggesting: Sendable {
    var isAvailable: Bool { get }

    func suggestions(for destinationName: String, localeIdentifier: String) async throws -> [String]
}

// MARK: - FoundationModelTripNameSuggester

struct FoundationModelTripNameSuggester: TripNameSuggesting {
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func suggestions(for destinationName: String, localeIdentifier: String) async throws -> [String] {
        let instructions = Instructions {
            """
            You name personal trips with ideas that feel unique to their destination, not generic
            travel templates. Use your general knowledge of the destination's cities, landscape,
            food, culture, history, or a recognisable local feeling. Make each of the four titles
            take a different angle. At most one title may include the destination's name.
            Never use template phrases such as "Discover [place]", "[place] escape", "My trip to
            [place]", or "Adventure in [place]".

            Return exactly four concise titles in the requested locale: 2–5 words each, no
            quotation marks, emojis, hashtags, dates, explanations, or markdown.
            """
        }
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(generating: GeneratedTripNameIdeas.self) {
            """
            Create four distinctive trip title ideas for a trip to (destinationName).
            Write in (localeIdentifier). Use destination-specific imagery rather than generic
            travel wording. Vary the ideas across different aspects of the place.
            """
        }

        return response.content.names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: []) { uniqueNames, name in
                guard !uniqueNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
                    return
                }

                uniqueNames.append(name)
            }
    }
}

// MARK: - GeneratedTripNameIdeas

@Generable
private struct GeneratedTripNameIdeas {
    @Guide(description: "Exactly four destination-specific, varied trip titles. Each is 2–5 words; avoid generic travel templates.")
    var names: [String]
}
