import Foundation
import Repository
import SwiftUI

enum NextTripCompatibility {
    case homeCountryMissing
    case compatible
    case adapterNeeded
    case converterRequired

    init(homeCountry: CountrySnapshot?, destination: CountrySnapshot) {
        guard let homeCountry else {
            self = .homeCountryMissing
            return
        }

        guard homeCountry.code != destination.code else {
            self = .compatible
            return
        }

        guard Self.isVoltageCompatible(homeCountry.voltage, destination.voltage) else {
            self = .converterRequired
            return
        }

        self = homeCountry.plugTypeIDs.contains(where: destination.plugTypeIDs.contains)
            ? .compatible
            : .adapterNeeded
    }

    var symbolName: String {
        switch self {
        case .homeCountryMissing: "house.badge.questionmark"
        case .compatible: "checkmark.circle.fill"
        case .adapterNeeded: "poweroutlet.type.a.fill"
        case .converterRequired: "bolt.trianglebadge.exclamationmark.fill"
        }
    }

    var tint: Color {
        switch self {
        case .homeCountryMissing: WidgetPalette.secondaryText
        case .compatible: WidgetPalette.frequency
        case .adapterNeeded: .yellow
        case .converterRequired: .orange
        }
    }

    var titleKey: String {
        switch self {
        case .homeCountryMissing: "widget.next.trip.compatibility.home.missing.title"
        case .compatible: "widget.next.trip.compatibility.compatible.title"
        case .adapterNeeded: "widget.next.trip.compatibility.adapter.title"
        case .converterRequired: "widget.next.trip.compatibility.converter.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .homeCountryMissing: "widget.next.trip.compatibility.home.missing.description"
        case .compatible: "widget.next.trip.compatibility.compatible.description"
        case .adapterNeeded: "widget.next.trip.compatibility.adapter.description"
        case .converterRequired: "widget.next.trip.compatibility.converter.description"
        }
    }

    private static func isVoltageCompatible(_ lhs: String, _ rhs: String) -> Bool {
        let lhsVoltages = voltages(in: lhs)
        let rhsVoltages = voltages(in: rhs)

        guard !lhsVoltages.isEmpty, !rhsVoltages.isEmpty else {
            return true
        }

        return lhsVoltages.contains { lhsVoltage in
            rhsVoltages.contains { rhsVoltage in
                abs(lhsVoltage - rhsVoltage) <= 20
            }
        }
    }

    private static func voltages(in value: String) -> [Int] {
        value.components(separatedBy: .decimalDigits.inverted)
            .compactMap(Int.init)
    }
}

struct NextTripCompatibilityCard: View {
    let compatibility: NextTripCompatibility

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: compatibility.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(compatibility.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                WidgetStrings.text(compatibility.titleKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText)

                WidgetStrings.text(compatibility.descriptionKey)
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WidgetLayout.cardPadding)
        .background(compatibility.tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct NextTripCompactCompatibility: View {
    let compatibility: NextTripCompatibility

    var body: some View {
        Label(WidgetStrings.string(compatibility.titleKey), systemImage: compatibility.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(compatibility.tint)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(compatibility.tint.opacity(0.12))
            .clipShape(Capsule())
    }
}
