import Foundation
import Observation
import Repository

// MARK: - PlugDetailViewModelType

@MainActor
protocol PlugDetailViewModelType: AnyObject, Observable {
    var plug: Plug { get }
    var description: LocalizedStringResource { get }
    var shareText: String { get }
}

// MARK: - PlugDetailViewModel

@Observable
@MainActor
final class PlugDetailViewModel: PlugDetailViewModelType {
    @ObservationIgnored let plug: Plug
    /// `LocalizedStringResource`, not `String`: this is assigned once in `init` and read
    /// much later by the view, so resolving it here would pin whatever locale was active
    /// when the screen was constructed.
    let description: LocalizedStringResource

    var shareText: String {
        LocalizationKeys.plugShareText.string(
            LocalizationKeys.plugTypePrefix.string(plug.id),
            String(localized: plug.plugType.shortInfoResource),
            plug.pinDiameter,
            plug.pinSpacing,
            plug.ratedAmperage
        )
    }

    init(plug: Plug) {
        self.plug = plug
        self.description = switch PlugType(rawValue: plug.id) ?? .unknown {
        case .a: LocalizationKeys.plugTypeADescription
        case .b: LocalizationKeys.plugTypeBDescription
        case .c: LocalizationKeys.plugTypeCDescription
        case .d: LocalizationKeys.plugTypeDDescription
        case .e: LocalizationKeys.plugTypeEDescription
        case .f: LocalizationKeys.plugTypeFDescription
        case .g: LocalizationKeys.plugTypeGDescription
        case .h: LocalizationKeys.plugTypeHDescription
        case .i: LocalizationKeys.plugTypeIDescription
        case .j: LocalizationKeys.plugTypeJDescription
        case .k: LocalizationKeys.plugTypeKDescription
        case .l: LocalizationKeys.plugTypeLDescription
        case .m: LocalizationKeys.plugTypeMDescription
        case .n: LocalizationKeys.plugTypeNDescription
        case .o: LocalizationKeys.plugTypeODescription
        case .unknown: LocalizationKeys.plugTypeUnknownShortInfo
        }
    }
}

#if DEBUG

// MARK: - PreviewPlugDetailViewModel

@Observable
@MainActor
final class PreviewPlugDetailViewModel: PlugDetailViewModelType {
    var plug: Plug
    var description: LocalizedStringResource
    var shareText: String

    init(plug: Plug) {
        self.plug = plug
        self.description = plug.plugType.shortInfoResource
        self.shareText = "\(plug.id): \(String(localized: plug.plugType.shortInfoResource))"
    }
}
#endif
