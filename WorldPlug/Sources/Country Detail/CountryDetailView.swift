import MapKit
import Repository
import SwiftUI

// MARK: - CountryDetailView

struct CountryDetailView<ViewModel: CountryDetailViewModelType>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.homeCountryViewModel) private var homeCountryViewModel
    @Environment(\.locale) private var locale
    @State private var viewModel: ViewModel
    @State private var selectedPlug: Plug?
    @State private var pendingSelectedPlug: Plug?

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
        }
        .task(id: viewModel.country.code) {
            await viewModel.loadMapFocus()
        }
        .onAppear {
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
        .sheet(isPresented: isInfoSheetPresentedBinding, onDismiss: presentPendingPlug) {
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

                    if viewModel.showsPlugStrip {
                        collapsedPlugStrip
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
        .animation(.smooth(duration: 0.28, extraBounce: 0), value: viewModel.selectedDetent)
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

            if let compatibility = viewModel.compatibility, !viewModel.isHomeCountry {
                CountryCompatibilityPill(summary: compatibility)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: viewModel.isHeaderDetent ? .center : .leading
        )
    }

    private var collapsedPlugStrip: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(viewModel.primaryPlugsTitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.textLight)
                .textCase(.uppercase)

            if viewModel.compatiblePlugs.isEmpty {
                Text(LocalizationKeys.countryDetailNoCompatiblePlugs.localized)
                    .font(.subheadline)
                    .foregroundStyle(.textLight)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .md) {
                        ForEach(viewModel.compatiblePlugs) { plug in
                            Button {
                                openPlugDetail(plug)
                            } label: {
                                CountryDetailPlugChip(plug: plug)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, .xs)
                }
                .scrollClipDisabled()
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: .xl) {
            detailSection(title: LocalizationKeys.countryDetailElectricalSetup.localized) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 132), spacing: .md)],
                    spacing: .md
                ) {
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

            if viewModel.showsCompatibilityOverview {
                detailSection(title: LocalizationKeys.countryDetailCompatibilityOverview.localized) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 104), spacing: .md)],
                        spacing: .md
                    ) {
                        CompatibilityCountCard(
                            title: LocalizationKeys.compatibilityLegendCompatibleTitle.localized,
                            count: viewModel.compatiblePlugs.count,
                            color: .green,
                            symbol: .checkmarkCircleFill
                        )
                        CompatibilityCountCard(
                            title: LocalizationKeys.compatibilityLegendAdapterTitle.localized,
                            count: viewModel.adapterPlugs.count,
                            color: .orange,
                            symbol: .powerPlugFill
                        )
                        CompatibilityCountCard(
                            title: LocalizationKeys.compatibilityLegendConverterTitle.localized,
                            count: viewModel.converterPlugs.count,
                            color: .red,
                            symbol: .exclamationMarkTriangle
                        )
                    }
                }
            }

            detailSection(title: LocalizationKeys.countryDetailAllPlugs.localized) {
                VStack(spacing: .md) {
                    ForEach(viewModel.country.sortedPlugs) { plug in
                        Button {
                            openPlugDetail(plug)
                        } label: {
                            CountryDetailPlugRow(
                                plug: plug,
                                compatibility: viewModel.plugCompatibility(for: plug)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
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

    private func openPlugDetail(_ plug: Plug) {
        pendingSelectedPlug = plug
        viewModel.isInfoSheetPresented = false
    }

    private func presentPendingPlug() {
        selectedPlug = pendingSelectedPlug
        pendingSelectedPlug = nil
    }

    private func handleBackNavigation() {
        viewModel.isInfoSheetPresented = false
        dismiss()
    }
}

extension CountryDetailView where ViewModel == CountryDetailViewModel {
    init(
        country: Country,
        compatibility: CountryCompatibilitySummary?
    ) {
        self.init(viewModel: CountryDetailViewModel(country: country, compatibility: compatibility))
    }
}

// MARK: - CountryCompatibilityPill

private struct CountryCompatibilityPill: View {
    let summary: CountryCompatibilitySummary

    var body: some View {
        HStack(spacing: .xs) {
            summary.icon.image
                .imageScale(.small)

            Text(summary.title)
                .lineLimit(1)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(summary.color)
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(summary.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - CountryDetailPlugChip

private struct CountryDetailPlugChip: View {
    let plug: Plug

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            SFSymbols.plugSymbol(for: plug.plugType)
                .image
                .font(.title3)
                .foregroundStyle(.textRegular)

            Text(LocalizationKeys.plugTypePrefix.localized(plug.id))
                .font(.callout.weight(.semibold))
                .foregroundStyle(.textRegular)
        }
        .frame(width: 148, alignment: .leading)
        .padding(.lg)
        .background(.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

// MARK: - CompatibilityCountCard

private struct CompatibilityCountCard: View {
    let title: String
    let count: Int
    let color: Color
    let symbol: SFSymbols

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            symbol.image
                .foregroundStyle(color)
                .font(.body)

            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(.textRegular)

            Text(title)
                .font(.caption)
                .foregroundStyle(.textLight)
                .lineLimit(2, reservesSpace: true)
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
    let compatibility: PlugCompatibility?

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

            Spacer(minLength: .md)

            if let compatibility {
                CountryDetailCompatibilityBadge(
                    compatibility: compatibility
                )
            }

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

// MARK: - CountryDetailCompatibilityBadge

private struct CountryDetailCompatibilityBadge: View {
    let compatibility: PlugCompatibility
    
    var body: some View {
        Image(systemName: iconName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var iconName: String {
        switch compatibility {
        case .compatible: "checkmark.circle.fill"
        case .adapterNeeded: "powerplug.fill"
        case .converterRequired: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch compatibility {
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
        compatibility: CountryCompatibilitySummary? = .adapterNeeded,
        isHomeCountry: Bool = false,
        showsCompatibilityOverview: Bool = false
    ) {
        let country = CountryDetailPreviewFixtures.makeCountry()
        let viewModel = PreviewCountryDetailViewModel(
            country: country,
            compatibility: compatibility,
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
        compatibility: .converterRequired,
        showsCompatibilityOverview: true
    )
}

#Preview("Large") {
    CountryDetailPreview(detent: .large, showsCompatibilityOverview: true)
}

#Preview("Home Country") {
    CountryDetailPreview(
        detent: .custom(CountrySummaryDetent.self),
        compatibility: nil,
        isHomeCountry: true
    )
}
#endif
