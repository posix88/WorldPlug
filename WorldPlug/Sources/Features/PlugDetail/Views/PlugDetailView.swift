import Analytics
import Repository
import SwiftUI

// MARK: - PlugDetailView

struct PlugDetailView<ViewModel: PlugDetailViewModelType>: View {
    @Environment(\.analyticsTracker) private var analyticsTracker
    @State private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .xxl) {
                PlugDetailHero(plugID: viewModel.plug.id)
                PlugDetailOverview(description: viewModel.description)
                PlugDetailSpecifications(plug: viewModel.plug)
                images
            }
            .padding(.bottom, .xxxl)
        }
        .onAppear {
            analyticsTracker.screen(.plugDetail)
        }
        .background { AppMeshBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: viewModel.shareText,
                    subject: Text(LocalizationKeys.plugTypePrefix.localized(viewModel.plug.id))
                ) {
                    Label(LocalizationKeys.plugShare.localized, systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - PlugDetailHero

private struct PlugDetailHero: View {
    let plugID: String

    var body: some View {
        VStack(spacing: .lg) {
            SFSymbols.plugSymbol(for: PlugType(rawValue: plugID) ?? .a)
                .image
                .font(.system(size: DesignTokens.Size.heroIcon, weight: .light))
                .foregroundStyle(.textRegular)
                .padding(.xl)
                .background(.cardSurface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: DesignTokens.Radius.small, x: 0, y: 4)

            Text(LocalizationKeys.plugTypePrefix.localized(plugID))
                .font(.title.weight(.bold))
                .foregroundStyle(.textRegular)
        }
        .padding(.top, .lg)
    }
}

// MARK: - PlugDetailOverview

private struct PlugDetailOverview: View {
    let description: String

    var body: some View {
        Card(shadow: .subtle) {
            VStack(alignment: .leading, spacing: .lg) {
                PlugDetailSectionHeader(
                    icon: .infoCircleFill,
                    title: LocalizationKeys.plugOverview.localized,
                    color: .buttonInfoTint
                )

                Text(description)
                    .font(.body)
                    .foregroundStyle(.textRegular)
                    .lineSpacing(CGFloat.xs)
            }
        }
        .padding(.horizontal, .xl)
    }
}

// MARK: - PlugDetailSpecifications

private struct PlugDetailSpecifications: View {
    let plug: Plug

    var body: some View {
        Card(shadow: .subtle) {
            VStack(alignment: .leading, spacing: .lg) {
                PlugDetailSectionHeader(
                    icon: .boltCircleFill,
                    title: LocalizationKeys.plugSpecifications.localized,
                    color: .voltTint
                )

                SpecificationRow(
                    icon: .powerPlug,
                    title: LocalizationKeys.pinDiameter.localized,
                    value: plug.pinDiameter,
                    color: .voltTint
                )
                SpecificationRow(
                    icon: .waveform,
                    title: LocalizationKeys.pinSpacing.localized,
                    value: plug.pinSpacing,
                    color: .frequencyTint
                )
                SpecificationRow(
                    icon: .batteryFull,
                    title: LocalizationKeys.ratedAmperage.localized,
                    value: plug.ratedAmperage,
                    color: .buttonInfoTint
                )

                VStack(alignment: .leading, spacing: .sm) {
                    Text(LocalizationKeys.alsoKnownAs.localized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.textLight)

                    Text(plug.alsoKnownAs)
                        .font(.subheadline)
                        .foregroundStyle(.textRegular)
                        .padding(.horizontal, .lg)
                        .padding(.vertical, .md)
                        .background(.surfaceSecondary)
                        .roundedCorner(radius: DesignTokens.Radius.small)
                }
            }
        }
        .padding(.horizontal, .xl)
    }
}

// MARK: - PlugDetailSectionHeader

private struct PlugDetailSectionHeader: View {
    let icon: SFSymbols
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: .sm) {
            icon.image
                .imageScale(.medium)
                .foregroundStyle(color)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.textRegular)
        }
    }
}

extension PlugDetailView where ViewModel == PlugDetailViewModel {
    init(plug: Plug) {
        self.init(viewModel: PlugDetailViewModel(plug: plug))
    }
}

extension PlugDetailView {
    @ViewBuilder
    var images: some View {
        if !viewModel.plug.images.isEmpty {
            Card(shadow: .subtle) {
                VStack(alignment: .leading, spacing: .lg) {
                    HStack(spacing: .sm) {
                        SFSymbols.photo
                            .image
                            .imageScale(.medium)
                            .foregroundStyle(.textLight)

                        Text(LocalizationKeys.plugImages.localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.textRegular)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .lg) {
                            ForEach(viewModel.plug.images, id: \.self) { url in
                                PlugReferenceImage(url: url)
                            }
                        }
                        .padding(.horizontal, .lg)
                    }
                }
            }
            .padding(.horizontal, .xl)
        }
    }
}

// MARK: - PlugReferenceImage

private struct PlugReferenceImage: View {
    let url: URL

    @State private var reloadID = 0

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()

            case .failure:
                Button {
                    reloadID += 1
                } label: {
                    VStack(spacing: .xs) {
                        SFSymbols.photo.image
                            .imageScale(.large)

                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.textLighter)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizationKeys.retry.localized)

            case .empty:
                ProgressView()
                    .tint(.textLighter)

            @unknown default:
                EmptyView()
            }
        }
        .id(reloadID)
        .frame(width: DesignTokens.Size.referenceImage, height: DesignTokens.Size.referenceImage)
        .background(.surfaceSecondary)
        .roundedCorner(radius: DesignTokens.Radius.medium)
    }
}

// MARK: - SpecificationRow

private struct SpecificationRow: View {
    let icon: SFSymbols
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: .lg) {
            HStack(spacing: .sm) {
                icon.image
                    .imageScale(.medium)
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.textRegular)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .padding(.horizontal, .lg)
                .padding(.vertical, .sm)
                .background(color.opacity(0.1))
                .roundedCorner(radius: DesignTokens.Radius.small)
        }
    }
}

#if DEBUG
#Preview {
    let plug = Plug(
        id: "A",
        images: [
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_sock_l.png")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_dia_plug_l.png")!
        ],
        specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
    )
    return NavigationStack {
        PlugDetailView(viewModel: PreviewPlugDetailViewModel(plug: plug))
    }
}
#endif
