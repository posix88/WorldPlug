import Analytics
import MapKit
import Repository
import SwiftUI

// MARK: - CountryDetailView

struct CountryDetailView<ViewModel: CountryDetailViewModelType>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.premiumEntitlement) private var premiumEntitlement
    @Environment(\.analyticsTracker) private var analyticsTracker
    @Environment(\.travelPreferencesStore) private var travelPreferencesStore
    @State private var viewModel: ViewModel
    @State private var selectedPlug: Plug?
    @State private var pendingSelectedPlug: Plug?
    @State private var dismissAfterSheet = false

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Map(position: mapPositionBinding, interactionModes: [.pan, .zoom]) {
            if let mapFocus = viewModel.mapFocus {
                Annotation(countryName, coordinate: mapFocus.coordinate, anchor: .center) {
                    CountryMapFocusPin()
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(countryName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBackNavigation()
                } label: {
                    Image(systemName: "chevron.backward")
                        .imageScale(.medium)
                }
                .accessibilityLabel(Text("Back"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleHomeCountry(using: homeCountryViewModel)
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

            if premiumEntitlement.isPremium {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        travelPreferencesStore.toggleSavedCountry(code: viewModel.country.code)
                    } label: {
                        Image(
                            systemName: travelPreferencesStore.isSavedCountry(code: viewModel.country.code)
                                ? "star.fill"
                                : "star"
                        )
                        .imageScale(.medium)
                    }
                    .accessibilityLabel(
                        travelPreferencesStore.isSavedCountry(code: viewModel.country.code)
                            ? LocalizationKeys.savedCountriesRemove.localized
                            : LocalizationKeys.savedCountriesAdd.localized
                    )
                }
            }
        }
        .task(id: viewModel.country.code) {
            await viewModel.loadMapFocus(reduceMotion: reduceMotion)
        }
        .onAppear {
            analyticsTracker.screen(.countryDetail)
            viewModel.isInfoSheetPresented = true
            viewModel.syncHomeCountry(with: homeCountryViewModel)
        }
        .onDisappear {
            viewModel.isInfoSheetPresented = false
        }
        .onChange(of: homeCountryViewModel.homeCountryCode) { _, _ in
            viewModel.syncHomeCountry(with: homeCountryViewModel)
        }
        .navigationDestination(item: $selectedPlug) { plug in
            PlugDetailView(plug: plug)
        }
        .sheet(isPresented: isInfoSheetPresentedBinding, onDismiss: handleInfoSheetDismissed) {
            countryInfoSheet
                .presentationDetents(
                    [
                        .custom(CountryHeaderDetent.self),
                        .custom(CountrySummaryDetent.self),
                        .medium,
                        .large
                    ],
                    selection: selectedDetentBinding
                )
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(
                    viewModel.isLargeDetent ? .scrolls : .resizes
                )
                .interactiveDismissDisabled()
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { viewModel.mapPosition },
            set: { viewModel.mapPosition = $0 }
        )
    }

    private var countryName: String {
        viewModel.country.localizedName(in: locale)
    }

    private var isInfoSheetPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isInfoSheetPresented },
            set: { viewModel.isInfoSheetPresented = $0 }
        )
    }

    private var selectedDetentBinding: Binding<PresentationDetent> {
        Binding(
            get: { viewModel.selectedDetent },
            set: { viewModel.selectedDetent = $0 }
        )
    }

    private var countryInfoSheet: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .xl) {
                    sheetHeader
                        .hidden()
                        .padding(.top, .xxl)

                    if !viewModel.isHeaderDetent {
                        electricalSection
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                )
                            )
                    }

                    if viewModel.isExpandedDetent {
                        expandedContent
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                )
                            )
                    }
                }
                .padding(.horizontal, .xxl)
                .padding(.bottom, viewModel.isExpandedDetent ? .xxl : .lg)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollDisabled(!viewModel.isLargeDetent)
            .scrollBounceBehavior(.basedOnSize)

            sheetHeader
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
    }

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: .md) {
            Text("\(viewModel.country.flagUnicode) \(countryName)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textRegular)
                .lineLimit(1)

            if viewModel.isHomeCountry {
                HomeCountryIndicator()
            }

        }
        .frame(
            maxWidth: .infinity,
            alignment: viewModel.isHeaderDetent ? .center : .leading
        )
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: .xl) {
            detailSection(title: LocalizationKeys.countryDetailAllPlugs.localized) {
                plugContent
            }
        }
    }

    private var electricalSection: some View {
        detailSection(title: LocalizationKeys.countryDetailElectricalSetup.localized) {
            electricalSetup
        }
    }

    private var electricalSetup: some View {
        Grid(horizontalSpacing: .md, verticalSpacing: .md) {
            GridRow {
                CountryInfoMetricCard(
                    icon: .boltCircleFill,
                    title: LocalizationKeys.accessibilityVoltage.localized(from: .accessibility),
                    value: viewModel.country.voltage,
                    color: .voltTint
                )

                CountryInfoMetricCard(
                    icon: .waveform,
                    title: LocalizationKeys.accessibilityFrequency.localized(from: .accessibility),
                    value: viewModel.country.frequency,
                    color: .frequencyTint
                )
            }
        }
    }

    @ViewBuilder
    private var plugContent: some View {
        if viewModel.showsCompatibilityOverview {
            VStack(alignment: .leading, spacing: .lg) {
                compatibilityGroup(.compatible, plugs: viewModel.compatiblePlugs)
                compatibilityGroup(.adapterNeeded, plugs: viewModel.adapterPlugs)
                compatibilityGroup(.converterRequired, plugs: viewModel.converterPlugs)
            }
        } else {
            plugRows(viewModel.country.sortedPlugs)
        }
    }

    @ViewBuilder
    private func compatibilityGroup(_ compatibility: PlugCompatibility, plugs: [Plug]) -> some View {
        if !plugs.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                Label {
                    Text("\(compatibility.title) (\(plugs.count))")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: compatibility.symbolName)
                }
                .foregroundStyle(compatibility.color)

                plugRows(plugs)
            }
        }
    }

    private func plugRows(_ plugs: [Plug]) -> some View {
        VStack(spacing: .md) {
            ForEach(plugs) { plug in
                Button {
                    openPlugDetail(plug)
                } label: {
                    CountryDetailPlugRow(plug: plug)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.textRegular)

            content()
        }
    }
}

// MARK: - Navigation

private extension CountryDetailView {
    func openPlugDetail(_ plug: Plug) {
        pendingSelectedPlug = plug
        viewModel.isInfoSheetPresented = false
    }

    func presentPendingPlug() {
        selectedPlug = pendingSelectedPlug
        pendingSelectedPlug = nil
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

extension CountryDetailView where ViewModel == CountryDetailViewModel {
    init(country: Country) {
        self.init(viewModel: CountryDetailViewModel(country: country))
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
        case .compatible: .green
        case .adapterNeeded: .orange
        case .converterRequired: .red
        }
    }
}

// MARK: - CountryMapFocusPin

private struct CountryMapFocusPin: View {
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
