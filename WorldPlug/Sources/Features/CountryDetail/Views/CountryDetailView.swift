import Analytics
import AppIntents
import MapKit
import Repository
import SwiftUI

// MARK: - CountryDetailView

struct CountryDetailView<ViewModel: CountryDetailViewModelType>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ViewModel
    @State private var selectedPlug: Plug?
    @State private var dismissAfterSheet = false

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Map(position: $viewModel.mapPosition, interactionModes: [.pan, .zoom]) {
            if let mapFocus = viewModel.mapFocus {
                Annotation(countryName, coordinate: mapFocus.coordinate, anchor: .center) {
                    CountryMapFocusPin(countryName: countryName)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top) {
            if viewModel.mapLoadState == .unavailable {
                CountryMapUnavailableNotice()
                    .padding(.top, .xl)
            }
        }
        .navigationTitle(countryName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .appEntityIdentifier(
            EntityIdentifier(for: CountryEntity.self, identifier: viewModel.country.code)
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBackNavigation()
                } label: {
                    Image(systemName: "chevron.backward")
                        .imageScale(.medium)
                }
                .accessibilityLabel(LocalizationKeys.navigationBack.localized)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.handleHomeCountryAction(using: homeCountryViewModel)
                } label: {
                    Image(systemName: viewModel.isHomeCountry ? "house.slash.fill" : "house.fill")
                        .imageScale(.medium)
                }
                .accessibilityLabel(
                    viewModel.isHomeCountry
                        ? LocalizationKeys.homeCountryRemove.localized
                        : LocalizationKeys.homeCountrySet.localized
                )
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: handleSavedCountryAction) {
                    Image(systemName: viewModel.savedCountrySymbolName)
                        .imageScale(.medium)
                        .overlay(alignment: .bottomTrailing) {
                            if !viewModel.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.background, .premiumTint)
                            }
                        }
                }
                .accessibilityLabel(viewModel.savedCountryAccessibilityLabel)
            }
        }
        .task(id: viewModel.country.code) {
            guard !AppDebugOverrides.isEnabled else {
                return
            }

            await viewModel.loadMapFocus(reduceMotion: reduceMotion)
        }
        .onAppear {
            if AppDebugOverrides.isEnabled {
                viewModel.selectedDetent = .large
            }
            viewModel.screenAppeared(using: homeCountryViewModel)
        }
        .onDisappear {
            viewModel.isInfoSheetPresented = false
        }
        .homeCountrySync(viewModel: viewModel)
        .navigationDestination(item: $selectedPlug) { plug in
            PlugDetailView(plug: plug)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $viewModel.isInfoSheetPresented, onDismiss: handleInfoSheetDismissed) {
            CountryInfoSheet(viewModel: viewModel, countryName: countryName)
                .presentationDetents(
                    [
                        .custom(CountryHeaderDetent.self),
                        .custom(CountrySummaryDetent.self),
                        .medium,
                        .large
                    ],
                    selection: $viewModel.selectedDetent
                )
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(
                    viewModel.isLargeDetent ? .scrolls : .resizes
                )
                .interactiveDismissDisabled()
                .ignoresSafeArea(edges: .bottom)
                .sheet(isPresented: $viewModel.isPremiumPaywallPresented) {
                    PremiumPaywallView(source: .countryDetailSave)
                }
                .alert(
                    homeCountryConfirmationTitle,
                    isPresented: $viewModel.isHomeCountryConfirmationPresented
                ) {
                    if viewModel.isHomeCountry {
                        Button(LocalizationKeys.homeCountryRemove.localized, role: .destructive) {
                            viewModel.confirmHomeCountryAction(using: homeCountryViewModel)
                        }
                    } else {
                        Button(LocalizationKeys.homeCountryUpdate.localized) {
                            viewModel.confirmHomeCountryAction(using: homeCountryViewModel)
                        }
                    }

                    Button(LocalizationKeys.generalCancel.localized, role: .cancel) {}
                } message: {
                    Text(homeCountryConfirmationMessage)
                }
        }
    }

    private var countryName: String {
        viewModel.country.localizedName(in: locale)
    }

    private var homeCountryConfirmationTitle: String {
        viewModel.isHomeCountry
            ? LocalizationKeys.homeCountryRemoveConfirmationTitle.localized
            : LocalizationKeys.homeCountryUpdateConfirmationTitle.localized
    }

    private var homeCountryConfirmationMessage: String {
        viewModel.isHomeCountry
            ? LocalizationKeys.homeCountryRemoveConfirmationMessage.localized
            : LocalizationKeys.homeCountryUpdateConfirmationMessage.localized(countryName)
    }

    private func handleSavedCountryAction() {
        viewModel.handleSavedCountryAction()
    }
}

// MARK: - Navigation

private extension CountryDetailView {
    func presentPendingPlug() {
        selectedPlug = viewModel.pendingPlug
        viewModel.pendingPlug = nil
    }

    func handleInfoSheetDismissed() {
        if dismissAfterSheet {
            dismissAfterSheet = false
            dismiss()
            return
        }

        presentPendingPlug()
    }

    func handleBackNavigation() {
        dismissAfterSheet = true
        viewModel.isInfoSheetPresented = false
    }
}

// MARK: - HomeCountrySyncModifier

/// Owns the `homeCountryCode` read that used to sit in `CountryDetailView`'s body purely to feed
/// an `.onChange`.
///
/// Reading an `@Environment` value in a body creates a dependency on it whether or not the body
/// renders it — and `CountryDetailView`'s body is the most expensive in the app (a `Map`, three
/// toolbar items, a four-detent sheet with all its presentation modifiers). Nothing there renders
/// `homeCountryCode`; only `viewModel.isHomeCountry` is drawn. Isolating the read here means a
/// home-country change re-runs this modifier's trivial body instead of all of that.
private struct HomeCountrySyncModifier<ViewModel: CountryDetailViewModelType>: ViewModifier {
    let viewModel: ViewModel
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel

    func body(content: Content) -> some View {
        content
            .onChange(of: homeCountryViewModel.homeCountryCode) { _, _ in
                viewModel.syncHomeCountry(with: homeCountryViewModel)
            }
    }
}

private extension View {
    func homeCountrySync(
        viewModel: some CountryDetailViewModelType
    ) -> some View {
        modifier(HomeCountrySyncModifier(viewModel: viewModel))
    }
}

// MARK: - CountryMapUnavailableNotice

private struct CountryMapUnavailableNotice: View {
    var body: some View {
        Label(LocalizationKeys.countryDetailMapUnavailable.localized, systemImage: "mappin.slash")
            .font(.caption.weight(.medium))
            .foregroundStyle(.textRegular)
            .padding(.horizontal, .lg)
            .padding(.vertical, .sm)
            .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - CountryInfoSheet

/// The detent-driven sheet over the map.
///
/// A separate `View` rather than a `private var countryInfoSheet: some View` on the parent: a
/// computed property is inlined into the enclosing body and shares its invalidation boundary, so
/// dragging the detent used to re-evaluate the `Map`, every toolbar item and all four
/// presentation modifiers along with the sheet's contents.
private struct CountryInfoSheet<ViewModel: CountryDetailViewModelType>: View {
    let viewModel: ViewModel
    let countryName: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .xl) {
                    // A hidden copy of the header, purely to reserve its height in the scrolling
                    // layout — the visible one is pinned in the ZStack below so it can stay put
                    // while the rest scrolls.
                    header
                        .hidden()
                        .padding(.top, .xxl)

                    if !viewModel.isHeaderDetent {
                        CountryElectricalSection(
                            voltage: viewModel.country.voltage,
                            frequency: viewModel.country.frequency
                        )
                        .transition(Self.sectionTransition)
                    }

                    if viewModel.isExpandedDetent {
                        CountryPlugsSection(viewModel: viewModel)
                            .transition(Self.sectionTransition)
                    }
                }
                .padding(.horizontal, .xxl)
                .padding(.bottom, viewModel.isExpandedDetent ? .xxl : .lg)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollDisabled(!viewModel.isLargeDetent)
            .scrollBounceBehavior(.basedOnSize)

            header
                .padding(.horizontal, .xxl)
                .padding(.top, viewModel.isHeaderDetent ? 0 : .xxl)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: viewModel.isHeaderDetent ? .center : .top
                )
        }
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.28, extraBounce: 0),
            value: viewModel.selectedDetent
        )
        .accessibilityIdentifier("countryDetail.infoSheet")
    }

    private static var sectionTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Kept as a property rather than its own `View` type because it is instantiated twice in the
    /// same body — once hidden for layout, once visible — and the two must stay byte-identical.
    private var header: CountryInfoSheetHeader {
        CountryInfoSheetHeader(
            flagUnicode: viewModel.country.flagUnicode,
            countryName: countryName,
            isHomeCountry: viewModel.isHomeCountry,
            isCentered: viewModel.isHeaderDetent
        )
    }
}

// MARK: - CountryInfoSheetHeader

private struct CountryInfoSheetHeader: View {
    let flagUnicode: String
    let countryName: String
    let isHomeCountry: Bool
    let isCentered: Bool

    var body: some View {
        HStack(alignment: .center, spacing: .md) {
            // `verbatim`: a flag emoji next to an already-localized country name is data, not a
            // translatable phrase. Without it the literal is a `LocalizedStringKey` and Xcode
            // extracts "%@ %@" into the catalog as a key.
            Text(verbatim: "\(flagUnicode) \(countryName)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textRegular)
                .lineLimit(1)

            if isHomeCountry {
                HomeCountryIndicator()
            }
        }
        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
    }
}

// MARK: - CountryElectricalSection

private struct CountryElectricalSection: View {
    let voltage: String
    let frequency: String

    var body: some View {
        CountryDetailSection(title: LocalizationKeys.countryDetailElectricalSetup.localized) {
            Grid(horizontalSpacing: .md, verticalSpacing: .md) {
                GridRow {
                    CountryInfoMetricCard(
                        icon: .boltCircleFill,
                        title: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                        value: voltage,
                        color: .voltTint
                    )

                    CountryInfoMetricCard(
                        icon: .waveform,
                        title: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                        value: frequency,
                        color: .frequencyTint
                    )
                }
            }
        }
    }
}

// MARK: - CountryPlugsSection

private struct CountryPlugsSection<ViewModel: CountryDetailViewModelType>: View {
    let viewModel: ViewModel

    var body: some View {
        CountryDetailSection(title: LocalizationKeys.countryDetailAllPlugs.localized) {
            if viewModel.showsCompatibilityOverview {
                VStack(alignment: .leading, spacing: .lg) {
                    CountryPlugCompatibilityGroup(
                        compatibility: .compatible,
                        plugs: viewModel.compatiblePlugs,
                        viewModel: viewModel
                    )
                    CountryPlugCompatibilityGroup(
                        compatibility: .adapterNeeded,
                        plugs: viewModel.adapterPlugs,
                        viewModel: viewModel
                    )
                    CountryPlugCompatibilityGroup(
                        compatibility: .converterRequired,
                        plugs: viewModel.converterPlugs,
                        viewModel: viewModel
                    )
                }
            } else {
                CountryPlugList(plugs: viewModel.allPlugs, viewModel: viewModel)
            }
        }
    }
}

// MARK: - CountryPlugCompatibilityGroup

private struct CountryPlugCompatibilityGroup<ViewModel: CountryDetailViewModelType>: View {
    let compatibility: PlugCompatibility
    let plugs: [Plug]
    let viewModel: ViewModel

    var body: some View {
        if !plugs.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                Label {
                    // A real key rather than an inline `"\(title) (\(count))"`: the latter
                    // registered "%@ (%@)" as a catalog key and hard-coded the parenthesized
                    // order. `count.formatted()` keeps the numeral locale-aware.
                    Text(
                        LocalizationKeys.compatibilityGroupCount.localized(
                            compatibility.title,
                            plugs.count.formatted()
                        )
                    )
                    .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: compatibility.symbolName)
                }
                .foregroundStyle(compatibility.color)

                CountryPlugList(plugs: plugs, viewModel: viewModel)
            }
        }
    }
}

// MARK: - CountryPlugList

private struct CountryPlugList<ViewModel: CountryDetailViewModelType>: View {
    let plugs: [Plug]
    /// The view model rather than an `(Plug) -> Void` closure — see `pendingPlug` on
    /// `CountryDetailViewModelType`.
    let viewModel: ViewModel

    var body: some View {
        VStack(spacing: .md) {
            ForEach(plugs) { plug in
                Button {
                    viewModel.openPlugDetail(plug)
                } label: {
                    CountryDetailPlugRow(plug: plug)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - CountryDetailSection

/// A titled section wrapper. Was a `detailSection(title:content:)` `@ViewBuilder` helper on the
/// parent; a real `View` type gives it its own invalidation boundary and its own type-check unit.
private struct CountryDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.textRegular)

            content
        }
    }
}

extension CountryDetailView where ViewModel == CountryDetailViewModel {
    init(
        country: Country,
        premiumEntitlement: any PremiumEntitlementProviding,
        travelPreferencesStore: any TravelPreferencesStoring,
        analyticsTracker: any AnalyticsTracker
    ) {
        self.init(
            viewModel: CountryDetailViewModel(
                country: country,
                premiumEntitlement: premiumEntitlement,
                travelPreferencesStore: travelPreferencesStore,
                analyticsTracker: analyticsTracker
            )
        )
    }
}

// MARK: - CountryInfoMetricCard

private struct CountryInfoMetricCard: View {
    let icon: SFSymbols
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            icon.image
                .foregroundStyle(color)
                .font(.title3)

            Text(title)
                .font(.caption)
                .foregroundStyle(.textLight)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.textRegular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.lg)
        .background(.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - CountryDetailPlugRow

private struct CountryDetailPlugRow: View {
    let plug: Plug

    var body: some View {
        HStack(spacing: .md) {
            SFSymbols.plugSymbol(for: plug.plugType)
                .image
                .font(.title3)
                .foregroundStyle(.textRegular)

            VStack(alignment: .leading, spacing: .xs) {
                Text(LocalizationKeys.plugTypePrefix.localized(plug.id))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.textRegular)

                Text(plug.plugType.shortInfoResource)
                    .font(.caption)
                    .foregroundStyle(.textLight)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SFSymbols.chevronRight.image
                .foregroundStyle(.textLighter)
                .imageScale(.small)
        }
        .padding(.horizontal, .lg)
        .padding(.vertical, .md)
        .background(.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension PlugCompatibility {
    var title: String {
        switch self {
        case .compatible:
            LocalizationKeys.compatibilityLegendCompatibleTitle.localized
        case .adapterNeeded:
            LocalizationKeys.compatibilityLegendAdapterTitle.localized
        case .converterRequired:
            LocalizationKeys.compatibilityLegendConverterTitle.localized
        }
    }

    var symbolName: String {
        switch self {
        case .compatible: "checkmark.circle.fill"
        case .adapterNeeded: "powerplug.fill"
        case .converterRequired: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .compatible: .statusReady
        case .adapterNeeded: .statusCheck
        case .converterRequired: .statusUnsafe
        }
    }
}

// MARK: - CountryMapFocusPin

private struct CountryMapFocusPin: View {
    let countryName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.voltTint.opacity(0.2))
                .frame(width: 56, height: 56)
                .blur(radius: 6)

            Circle()
                .fill(.voltTint.opacity(0.18))
                .frame(width: 42, height: 42)
                .blur(radius: 2)

            Circle()
                .stroke(.white.opacity(0.92), lineWidth: 3)
                .frame(width: 18, height: 18)

            Circle()
                .fill(.voltTint)
                .frame(width: 10, height: 10)
                .shadow(color: .voltTint.opacity(0.9), radius: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(countryName)
    }
}

#if DEBUG
private enum CountryDetailPreviewFixtures {
    static func makeCountry() -> Country {
        let plugs = [
            Plug(
                id: "C",
                images: [],
                specifications: .init(
                    pinDiameter: "4.0 mm",
                    pinSpacing: "19 mm",
                    ratedAmperage: "2.5 A / 16 A",
                    alsoKnownAs: "Europlug"
                )
            ),
            Plug(
                id: "F",
                images: [],
                specifications: .init(
                    pinDiameter: "4.8 mm",
                    pinSpacing: "19 mm",
                    ratedAmperage: "16 A",
                    alsoKnownAs: "Schuko"
                )
            ),
            Plug(
                id: "L",
                images: [],
                specifications: .init(
                    pinDiameter: "4.0 mm / 5.0 mm",
                    pinSpacing: "19 mm / 26 mm",
                    ratedAmperage: "10 A / 16 A",
                    alsoKnownAs: "CEI 23-50"
                )
            )
        ]

        return Country(
            code: "IT",
            voltage: "230 V",
            frequency: "50 Hz",
            flagUnicode: "🇮🇹",
            plugs: plugs
        )
    }

    static func makeMapFocus() -> CountryMapFocus {
        CountryMapFocus(
            coordinate: .init(latitude: 41.9028, longitude: 12.4964),
            region: MKCoordinateRegion(
                center: .init(latitude: 41.9028, longitude: 12.4964),
                latitudinalMeters: 900_000,
                longitudinalMeters: 900_000
            ),
            cameraDistance: 1_400_000
        )
    }
}

private struct CountryDetailPreview: View {
    @State private var viewModel: PreviewCountryDetailViewModel
    private let homeCountryViewModel: PreviewHomeCountryViewModel

    init(
        detent: PresentationDetent,
        isHomeCountry: Bool = false,
        showsCompatibilityOverview: Bool = false
    ) {
        let country = CountryDetailPreviewFixtures.makeCountry()
        let viewModel = PreviewCountryDetailViewModel(
            country: country,
            isHomeCountry: isHomeCountry,
            showsCompatibilityOverview: showsCompatibilityOverview
        )
        viewModel.selectedDetent = detent
        let mapFocus = CountryDetailPreviewFixtures.makeMapFocus()
        viewModel.mapFocus = mapFocus
        viewModel.mapPosition = .camera(
            MapCamera(
                centerCoordinate: mapFocus.coordinate,
                distance: mapFocus.cameraDistance,
                heading: 0,
                pitch: 8
            )
        )

        _viewModel = State(initialValue: viewModel)
        self.homeCountryViewModel = PreviewHomeCountryViewModel(
            homeCountryCode: isHomeCountry ? country.code : "US",
            plugTypeIDs: ["A", "B", "C"],
            homeVoltage: "120 V"
        )
    }

    var body: some View {
        NavigationStack {
            CountryDetailView(viewModel: viewModel)
        }
        .environment(\.homeCountryViewModel, homeCountryViewModel)
    }
}

#Preview("Compact") {
    CountryDetailPreview(detent: .custom(CountryHeaderDetent.self))
}

#Preview("Summary") {
    CountryDetailPreview(detent: .custom(CountrySummaryDetent.self))
}

#Preview("Medium Compatibility") {
    CountryDetailPreview(
        detent: .medium,
        showsCompatibilityOverview: true
    )
}

#Preview("Large") {
    CountryDetailPreview(detent: .large, showsCompatibilityOverview: true)
}

#Preview("Home Country") {
    CountryDetailPreview(
        detent: .custom(CountrySummaryDetent.self),
        isHomeCountry: true
    )
}
#endif
