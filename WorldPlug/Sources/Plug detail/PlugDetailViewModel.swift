import Observation
import Repository

// MARK: - PlugDetailViewModelType

@MainActor
protocol PlugDetailViewModelType: AnyObject, Observable {
    var plug: Plug { get }
    var description: String { get }
    var shareText: String { get }
}

// MARK: - PlugDetailViewModel

@Observable
@MainActor
final class PlugDetailViewModel: PlugDetailViewModelType {
    @ObservationIgnored let plug: Plug
    let description: String

    var shareText: String {
        LocalizationKeys.plugShareText.localized(
            LocalizationKeys.plugTypePrefix.localized(plug.id),
            plug.shortInfo,
            plug.pinDiameter,
            plug.pinSpacing,
            plug.ratedAmperage
        )
    }

    init(plug: Plug) {
        self.plug = plug
        self.description = switch PlugType(rawValue: plug.id) ?? .unknown {
        case .a: LocalizationKeys.plugTypeADescription.localized
        case .b: LocalizationKeys.plugTypeBDescription.localized
        case .c: LocalizationKeys.plugTypeCDescription.localized
        case .d: LocalizationKeys.plugTypeDDescription.localized
        case .e: LocalizationKeys.plugTypeEDescription.localized
        case .f: LocalizationKeys.plugTypeFDescription.localized
        case .g: LocalizationKeys.plugTypeGDescription.localized
        case .h: LocalizationKeys.plugTypeHDescription.localized
        case .i: LocalizationKeys.plugTypeIDescription.localized
        case .j: LocalizationKeys.plugTypeJDescription.localized
        case .k: LocalizationKeys.plugTypeKDescription.localized
        case .l: LocalizationKeys.plugTypeLDescription.localized
        case .m: LocalizationKeys.plugTypeMDescription.localized
        case .n: LocalizationKeys.plugTypeNDescription.localized
        case .o: LocalizationKeys.plugTypeODescription.localized
        case .unknown: plug.info
        }
    }
}

#if DEBUG

// MARK: - PreviewPlugDetailViewModel

@Observable
@MainActor
final class PreviewPlugDetailViewModel: PlugDetailViewModelType {
    var plug: Plug
    var description: String
    var shareText: String

    init(plug: Plug) {
        self.plug = plug
        self.description = plug.shortInfo
        self.shareText = "\(plug.name): \(plug.shortInfo)"
    }
}
#endif
