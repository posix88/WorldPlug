import CoreLocation
import MapKit
import Observation
import Repository
import SwiftUI

// MARK: - CountryDetailViewModelType

@MainActor
protocol CountryDetailViewModelType: AnyObject, Observable {
    var country: Country { get }
    var compatibility: CountryCompatibilitySummary? { get }
    var mapPosition: MapCameraPosition { get set }
    var mapFocus: CountryMapFocus? { get }
    var isInfoSheetPresented: Bool { get set }
    var selectedDetent: PresentationDetent { get set }
    var isHomeCountry: Bool { get }
    var compatiblePlugs: [Plug] { get }
    var adapterPlugs: [Plug] { get }
    var converterPlugs: [Plug] { get }
    var isLargeDetent: Bool { get }
    var isHeaderDetent: Bool { get }
    var isExpandedDetent: Bool { get }
    var showsPlugStrip: Bool { get }
    var showsCompatibilityOverview: Bool { get }
    var primaryPlugsTitle: String { get }
    var sheetBackgroundOpacity: CGFloat { get }

    func syncHomeCountry(with homeCountryViewModel: any HomeCountryViewModelType)
    func toggleHomeCountry(using homeCountryViewModel: any HomeCountryViewModelType)
    func toggleSheetExpansion()
    func plugCompatibility(for plug: Plug) -> PlugCompatibility?
    func loadMapFocus() async
}

// MARK: - CountryDetailViewModel

@Observable
@MainActor
final class CountryDetailViewModel: CountryDetailViewModelType {
    @ObservationIgnored let country: Country
    @ObservationIgnored let compatibility: CountryCompatibilitySummary?

    var mapPosition: MapCameraPosition = .region(.world)
    var mapFocus: CountryMapFocus?
    var isInfoSheetPresented = true
    var selectedDetent: PresentationDetent = .custom(CountryHeaderDetent.self)

    private(set) var isHomeCountry = false
    private(set) var compatiblePlugs: [Plug]
    private(set) var adapterPlugs: [Plug] = []
    private(set) var converterPlugs: [Plug] = []
    private var hasHomeCountry = false

    var isLargeDetent: Bool {
        selectedDetent == .large
    }

    var isHeaderDetent: Bool {
        selectedDetent == .custom(CountryHeaderDetent.self)
    }

    var isExpandedDetent: Bool {
        selectedDetent == .medium || selectedDetent == .large
    }

    var showsPlugStrip: Bool {
        !isHeaderDetent
    }

    var showsCompatibilityOverview: Bool {
        hasHomeCountry && !isHomeCountry
    }

    var primaryPlugsTitle: String {
        hasHomeCountry
            ? LocalizationKeys.countryDetailDirectlyCompatible.localized
            : LocalizationKeys.countryDetailPlugsInUse.localized
    }

    var sheetBackgroundOpacity: CGFloat {
        switch selectedDetent {
        case .large:
            1
        case .medium:
            0.82
        default:
            0.56
        }
    }

    init(country: Country, compatibility: CountryCompatibilitySummary?) {
        self.country = country
        self.compatibility = compatibility
        self.compatiblePlugs = country.sortedPlugs
    }

    func syncHomeCountry(with homeCountryViewModel: any HomeCountryViewModelType) {
        hasHomeCountry = !homeCountryViewModel.homeCountryCode.isEmpty
        isHomeCountry = homeCountryViewModel.homeCountryCode == country.code

        guard hasHomeCountry, !isHomeCountry else {
            compatiblePlugs = country.sortedPlugs
            adapterPlugs = []
            converterPlugs = []
            return
        }

        compatiblePlugs = country.sortedPlugs.filter { plugCompatibility(for: $0, using: homeCountryViewModel) == .compatible }
        adapterPlugs = country.sortedPlugs.filter { plugCompatibility(for: $0, using: homeCountryViewModel) == .adapterNeeded }
        converterPlugs = country.sortedPlugs.filter { plugCompatibility(for: $0, using: homeCountryViewModel) == .converterRequired }
    }

    func toggleHomeCountry(using homeCountryViewModel: any HomeCountryViewModelType) {
        if isHomeCountry {
            homeCountryViewModel.clearHome()
        } else {
            homeCountryViewModel.setHome(code: country.code)
        }
    }

    func toggleSheetExpansion() {
        withAnimation(.smooth(duration: 0.36, extraBounce: 0)) {
            selectedDetent = isExpandedDetent ? .custom(CountryHeaderDetent.self) : .large
        }
    }

    func plugCompatibility(for plug: Plug) -> PlugCompatibility? {
        guard hasHomeCountry, !isHomeCountry else {
            return nil
        }

        if compatiblePlugs.contains(where: { $0.id == plug.id }) {
            return .compatible
        }

        if adapterPlugs.contains(where: { $0.id == plug.id }) {
            return .adapterNeeded
        }

        if converterPlugs.contains(where: { $0.id == plug.id }) {
            return .converterRequired
        }

        return nil
    }

    func loadMapFocus() async {
        let lookup = CountryMapLookup(code: country.code)

        if let focus = await CountryMapGeocoder.shared.focus(for: lookup) {
            mapFocus = focus

            try? await Task.sleep(for: .milliseconds(220))

            withAnimation(.smooth(duration: 1.05, extraBounce: 0)) {
                mapPosition = .camera(
                    MapCamera(
                        centerCoordinate: focus.coordinate,
                        distance: focus.cameraDistance,
                        heading: 0,
                        pitch: 8
                    )
                )
            }
        }
    }

    private func plugCompatibility(
        for plug: Plug,
        using homeCountryViewModel: any HomeCountryViewModelType
    ) -> PlugCompatibility {
        homeCountryViewModel.plugCompatibility(for: plug, in: country)
    }
}

#if DEBUG

// MARK: - PreviewCountryDetailViewModel

@Observable
@MainActor
final class PreviewCountryDetailViewModel: CountryDetailViewModelType {
    var country: Country
    var compatibility: CountryCompatibilitySummary?
    var mapPosition: MapCameraPosition = .region(.world)
    var mapFocus: CountryMapFocus?
    var isInfoSheetPresented = true
    var selectedDetent: PresentationDetent = .custom(CountryHeaderDetent.self)
    var isHomeCountry = false
    var compatiblePlugs: [Plug]
    var adapterPlugs: [Plug] = []
    var converterPlugs: [Plug] = []
    var shouldShowCompatibilityOverview = false

    var isLargeDetent: Bool {
        selectedDetent == .large
    }

    var isHeaderDetent: Bool {
        selectedDetent == .custom(CountryHeaderDetent.self)
    }

    var isExpandedDetent: Bool {
        selectedDetent == .medium || selectedDetent == .large
    }

    var showsPlugStrip: Bool {
        !isHeaderDetent
    }

    var showsCompatibilityOverview: Bool { shouldShowCompatibilityOverview }

    var primaryPlugsTitle: String {
        LocalizationKeys.countryDetailPlugsInUse.localized
    }

    var sheetBackgroundOpacity: CGFloat {
        switch selectedDetent {
        case .large:
            1
        case .medium:
            0.82
        default:
            0.56
        }
    }

    var mapLabelSubtitle: String {
        mapFocus == nil
            ? LocalizationKeys.countryDetailMapLocating.localized
            : "\(country.voltage) • \(country.frequency)"
    }

    init(
        country: Country,
        compatibility: CountryCompatibilitySummary?,
        isHomeCountry: Bool = false,
        showsCompatibilityOverview: Bool = false
    ) {
        self.country = country
        self.compatibility = compatibility
        self.isHomeCountry = isHomeCountry
        self.shouldShowCompatibilityOverview = showsCompatibilityOverview
        self.compatiblePlugs = Array(country.sortedPlugs.prefix(1))
        self.adapterPlugs = Array(country.sortedPlugs.dropFirst().prefix(1))
        self.converterPlugs = Array(country.sortedPlugs.dropFirst(2))
    }

    func syncHomeCountry(with homeCountryViewModel: any HomeCountryViewModelType) {}
    func toggleHomeCountry(using homeCountryViewModel: any HomeCountryViewModelType) {}

    func toggleSheetExpansion() {
        selectedDetent = isExpandedDetent ? .custom(CountryHeaderDetent.self) : .large
    }

    func plugCompatibility(for plug: Plug) -> PlugCompatibility? {
        if compatiblePlugs.contains(where: { $0.id == plug.id }) {
            return .compatible
        }
        if adapterPlugs.contains(where: { $0.id == plug.id }) {
            return .adapterNeeded
        }
        if converterPlugs.contains(where: { $0.id == plug.id }) {
            return .converterRequired
        }
        return nil
    }
    func loadMapFocus() async {}
}
#endif

struct CountryHeaderDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        min(88, max(80, context.maxDetentValue * 0.12))
    }
}

struct CountrySummaryDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        min(208, max(196, context.maxDetentValue * 0.24))
    }
}
