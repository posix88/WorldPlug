//
//  SFSymbols.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 24/09/25.
//

import Repository
import SwiftUI

// MARK: - SFSymbols

/// A centralized enum for managing SF Symbols throughout the app
/// This provides better maintainability and consistency for icon usage
enum SFSymbols: String, CaseIterable {
    // MARK: - Navigation & Interface

    case chevronRight = "chevron.right"
    case chevronDown = "chevron.down"
    case chevronUp = "chevron.up"
    case chevronLeft = "chevron.left"
    case magnifyingGlass = "magnifyingglass"
    case xmarkCircleFill = "xmark.circle.fill"
    case photo

    // MARK: - Electrical & Power

    case boltCircle = "bolt.circle"
    case boltCircleFill = "bolt.circle.fill"
    case powerPlugFill = "powerplug.fill"
    case powerPlug = "powerplug"
    case waveform
    case waveformPathEcg = "waveform.path.ecg"
    case batteryFull = "battery.100"

    // MARK: - Information & Status

    case infoCircle = "info.circle"
    case infoCircleFill = "info.circle.fill"
    case checkmarkCircle = "checkmark.circle"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case exclamationMarkTriangle = "exclamationmark.triangle"
    case questionMarkCircle = "questionmark.circle"
    case questionMarkAppFill = "questionmark.app.fill"

    // MARK: - Actions

    case heartFill = "heart.fill"
    case heart
    case shareFill = "square.and.arrow.up.fill"
    case share = "square.and.arrow.up"
    case bookmarkFill = "bookmark.fill"
    case bookmark

    // MARK: - Geographic & Location

    case globeAmericas = "globe.americas"
    case globeEuropeAfrica = "globe.europe.africa"
    case globeAsiaAustralia = "globe.asia.australia"
    case mapFill = "map.fill"
    case location
    case locationFill = "location.fill"

    // MARK: - Plug Types (using existing system)

    case plugTypeA = "poweroutlet.type.a"
    case plugTypeB = "poweroutlet.type.b"
    case plugTypeC = "poweroutlet.type.c"
    case plugTypeD = "poweroutlet.type.d"
    case plugTypeE = "poweroutlet.type.e"
    case plugTypeF = "poweroutlet.type.f"
    case plugTypeG = "poweroutlet.type.g"
    case plugTypeH = "poweroutlet.type.h"
    case plugTypeI = "poweroutlet.type.i"
    case plugTypeJ = "poweroutlet.type.j"
    case plugTypeK = "poweroutlet.type.k"
    case plugTypeL = "poweroutlet.type.l"
    case plugTypeM = "poweroutlet.type.m"
    case plugTypeN = "poweroutlet.type.n"
    case plugTypeO = "poweroutlet.type.o"

    /// Returns the Image view for this symbol
    var image: Image {
        Image(systemName: rawValue)
    }
}

/// Extension to make plug symbol access easier
extension SFSymbols {
    static func plugSymbol(for plugType: PlugType) -> SFSymbols {
        switch plugType {
        case .a: .plugTypeA
        case .b: .plugTypeB
        case .c: .plugTypeC
        case .d: .plugTypeD
        case .e: .plugTypeE
        case .f: .plugTypeF
        case .g: .plugTypeG
        case .h: .plugTypeH
        case .i: .plugTypeI
        case .j: .plugTypeJ
        case .k: .plugTypeK
        case .l: .plugTypeL
        case .m: .plugTypeM
        case .n: .plugTypeN
        case .o: .plugTypeO
        case .unknown: SFSymbols(rawValue: "questionmark.app.fill") ?? .questionMarkAppFill
        }
    }
}
