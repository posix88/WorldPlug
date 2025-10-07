import Repository
import Translation

@Observable
@MainActor
final class PlugDetailViewModel {
    @ObservationIgnored let plug: Plug

    var isTranslating: Bool = false
    var translatedText: String?
    var showTranslation: Bool = false
    var translationError: String?

    init(plug: Plug) {
        self.plug = plug
    }

    func translate() async {
        guard !isTranslating else {
            return
        }

        isTranslating = true
        translationError = nil

        do {
            let session = TranslationSession(
                installedSource: Locale.Language(identifier: "en_US"),
                target: Locale.current.language
            )
            let response = try await session.translate(plug.info)
            translatedText = response.targetText
            showTranslation = true
        } catch {
            translationError = error.localizedDescription
        }
        isTranslating = false
    }
}
