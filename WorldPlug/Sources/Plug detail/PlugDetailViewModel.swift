import Repository

@Observable
@MainActor
final class PlugDetailViewModel {
    @ObservationIgnored let plug: Plug
    let description: String

    init(plug: Plug) {
        self.plug = plug
        self.description = switch plug.plugType {
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
