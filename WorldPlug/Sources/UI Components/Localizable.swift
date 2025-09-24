//
//  Localizable.swift
//  WorldPlug
//
//  Created by GitHub Copilot on 24/09/25.
//

import Foundation

extension String {
    /// Returns a localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version of the string with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

/// Centralized localization keys for better maintainability
enum LocalizationKeys {
    // MARK: - Main Navigation
    static let appTitle = "app.title"
    
    // MARK: - Countries List View
    static let countriesTitle = "countries.title"
    static let countriesAvailable = "countries.available"
    static let searchCountriesPlaceholder = "search.countries.placeholder"
    
    // MARK: - Country Card
    static let compatiblePlugs = "compatible.plugs"
    static let plugTypePrefix = "plug.type.prefix"
    static let plugType = "plug.type"
    
    // MARK: - General
    static let loading = "loading"
    static let error = "error"
    static let retry = "retry"
}
