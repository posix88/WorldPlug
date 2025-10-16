import Repository
import SwiftUI

// MARK: - PlugDetailView

struct PlugDetailView: View {
    @State private var viewModel: PlugDetailViewModel

    init(plug: Plug) {
        let viewModel = PlugDetailViewModel(plug: plug)
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .xxl) {
                // Hero section with plug icon and title
                VStack(spacing: .lg) {
                    // Large plug icon using SF Symbols
                    SFSymbols.plugSymbol(for: PlugType(rawValue: viewModel.plug.id) ?? .a)
                        .image
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.textRegular)
                        .padding(.xl)
                        .background(.cardSurface)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                    // Plug name and type
                    Text(LocalizationKeys.plugTypePrefix.localized(viewModel.plug.id))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.textRegular)
                }
                .padding(.top, .lg)

                // Overview section
                Card(shadow: .subtle) {
                    VStack(alignment: .leading, spacing: .lg) {
                        HStack(spacing: .sm) {
                            SFSymbols.infoCircleFill
                                .image
                                .imageScale(.medium)
                                .foregroundStyle(.buttonInfoTint)

                            Text(LocalizationKeys.plugOverview.localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textRegular)
                        }

                        // Text content
                        Text(viewModel.description)
                            .font(.body)
                            .foregroundStyle(.textRegular)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, .xl)

                // Specifications section
                Card(shadow: .subtle) {
                    VStack(alignment: .leading, spacing: .lg) {
                        HStack(spacing: .sm) {
                            SFSymbols.boltCircleFill
                                .image
                                .imageScale(.medium)
                                .foregroundStyle(.voltTint)

                            Text(LocalizationKeys.plugSpecifications.localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textRegular)
                        }

                        // Specifications grid
                        SpecificationRow(
                            icon: SFSymbols.powerPlug,
                            title: LocalizationKeys.pinDiameter.localized,
                            value: viewModel.plug.pinDiameter,
                            color: .voltTint
                        )

                        SpecificationRow(
                            icon: SFSymbols.waveform,
                            title: LocalizationKeys.pinSpacing.localized,
                            value: viewModel.plug.pinSpacing,
                            color: .frequencyTint
                        )

                        SpecificationRow(
                            icon: SFSymbols.batteryFull,
                            title: LocalizationKeys.ratedAmperage.localized,
                            value: viewModel.plug.ratedAmperage,
                            color: .buttonInfoTint
                        )

                        // Also known as
                        VStack(alignment: .leading, spacing: .sm) {
                            Text(LocalizationKeys.alsoKnownAs.localized)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textLight)

                            Text(viewModel.plug.alsoKnownAs)
                                .font(.subheadline)
                                .foregroundStyle(.textRegular)
                                .padding(.horizontal, .lg)
                                .padding(.vertical, .md)
                                .background(.surfaceSecondary)
                                .roundedCorner(radius: 8)
                        }
                    }
                }
                .padding(.horizontal, .xl)
            }
            .padding(.bottom, .xxxl)
        }
        .background(.backgroundSurface)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

extension PlugDetailView {
    /// Not displayed ATM
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
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .background(.surfaceSecondary)
                                        .roundedCorner(radius: 12)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.surfaceSecondary)
                                        .frame(width: 120, height: 120)
                                        .overlay {
                                            SFSymbols.photo.image
                                                .foregroundStyle(.textLighter)
                                                .imageScale(.large)
                                        }
                                }
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
                .roundedCorner(radius: 8)
        }
    }
}

#if DEBUG
import SwiftData

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plug.self, configurations: config)
    let plug = Plug(
        id: "A",
        name: "Type A",
        shortInfo: "short info",
        info: "Est ea non incididunt amet proident aliqua mollit sint voluptate. Voluptate dolor ex est minim nulla qui. Occaecat aliquip sint labore anim do. Sint labore eu do officia consectetur. Ea incididunt enim commodo officia ullamco officia sint labore officia labore. Anim est aute eu culpa voluptate tempor dolore labore exercitation mollit non aliquip. Dolore amet sint consectetur eu nulla ullamco elit do enim officia officia reprehenderit ex aliqua elit.",
        images: [
            URL(string: "https://balidave.com/wp-content/uploads/2022/11/best-hotel-bali.jpeg")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_3d_sock_l.png")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_dia_plug_l.png")!,
            URL(string: "https://www.iec.ch/themes/custom/iec/images/world-plugs/types/A/A_dia_sock_l.png")!
        ],
        specifications: .init(pinDiameter: "1.5mm", pinSpacing: "12.7mm", ratedAmperage: "10A", alsoKnownAs: "AS/NZS 3112")
    )
    container.mainContext.insert(plug)
    return NavigationStack {
        PlugDetailView(plug: plug)
    }
}
#endif
