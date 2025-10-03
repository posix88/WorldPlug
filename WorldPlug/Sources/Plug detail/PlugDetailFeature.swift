import ComposableArchitecture
import CoreGraphics
import Repository
import Translation

@Reducer
struct PlugDetailFeature {
    @ObservableState
    struct State {
        var plug: Plug
        var viewSize: CGSize = .zero
        var isTranslating: Bool = false
        var translatedText: String?
        var showTranslation: Bool = false
        var translationError: String?
    }

    enum Action {
        case sizeUpdated(CGSize)
        case translateTapped
        case translationCompleted(String)
        case translationFailed(String)
        case toggleTranslation
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sizeUpdated(let newSize):
                state.viewSize = newSize
                return .none

            case .translateTapped:
                guard !state.isTranslating else {
                    return .none
                }

                state.isTranslating = true
                state.translationError = nil

                return .run { [text = state.plug.info] send in
                    do {
                        let session = TranslationSession(
                            installedSource: Locale.Language(identifier: "en_US"),
                            target: Locale.current.language
                        )
                        let response = try await session.translate(text)
                        await send(.translationCompleted(response.targetText))
                    } catch {
                        await send(.translationFailed(error.localizedDescription))
                    }
                }

            case .translationCompleted(let translated):
                state.isTranslating = false
                state.translatedText = translated
                state.showTranslation = true
                return .none

            case .translationFailed(let error):
                state.isTranslating = false
                state.translationError = error
                return .none

            case .toggleTranslation:
                state.showTranslation.toggle()
                return .none
            }
        }
    }
}
