//
//  Localizable.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 24/09/25.
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

    /// Returns a localized version of the string from a specific table
    func localized(from table: StringCatalog) -> String {
        NSLocalizedString(self, tableName: table.rawValue, comment: "")
    }

    /// Returns a localized version of the string from a specific table with format arguments
    func localized(from table: StringCatalog, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, tableName: table.rawValue, comment: ""), arguments: arguments)
    }
}

// MARK: - StringCatalog

enum StringCatalog: String {
    case main = "Localizable"
    case accessibility = "Accessibility"
}

// MARK: - LocalizationKeys

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

    // MARK: - Plug Detail View

    static let plugOverview = "plug.overview"
    static let plugSpecifications = "plug.specifications"
    static let plugImages = "plug.images"
    static let translateText = "translate.text"
    static let originalText = "original.text"
    static let translatedText = "translated.text"
    static let translationError = "translation.error"
    static let pinSpacing = "pin.spacing"
    static let pinDiameter = "pin.diameter"
    static let ratedAmperage = "rated.amperage"
    static let alsoKnownAs = "also.known.as"

    // MARK: - General

    static let loading = "loading"
    static let error = "error"
    static let retry = "retry"

    // MARK: - Accessibility

    static let accessibilityVoltage = "accessibility.voltage"
    static let accessibilityFrequency = "accessibility.frequency"
    static let accessibilityPlugTypesCount = "accessibility.plug.types.count"
    static let accessibilityCompatiblePlugTypes = "accessibility.compatible.plug.types"
    static let accessibilityPlugTypeLabel = "accessibility.plug.type.label"
    static let accessibilityPlugTypeHint = "accessibility.plug.type.hint"
    static let accessibilityCountryDetails = "accessibility.country.details"
    static let accessibilityCountryCardHint = "accessibility.country.card.hint"
    static let accessibilityExpandCountryDetails = "accessibility.expand.country.details"
    static let accessibilityCollapseCountryDetails = "accessibility.collapse.country.details"
    static let accessibilityShowDetailsHint = "accessibility.show.details.hint"
    static let accessibilityHideDetailsHint = "accessibility.hide.details.hint"

    // MARK: - Countries List Accessibility

    static let accessibilityCountriesHeader = "accessibility.countries.header"
    static let accessibilityCountriesList = "accessibility.countries.list"
    static let accessibilityCountriesListDescription = "accessibility.countries.list.description"
    static let accessibilityCountryAvailableCount = "accessibility.country.available.count"
    static let accessibilityEmptyState = "accessibility.empty.state"
    static let accessibilityEmptyStateDescription = "accessibility.empty.state.description"
    static let accessibilityNavigationTitle = "accessibility.navigation.title"
    static let accessibilitySearchActive = "accessibility.search.active"
    static let accessibilitySearchClear = "accessibility.search.clear"
    static let accessibilitySearchField = "accessibility.search.field"
    static let accessibilitySearchHint = "accessibility.search.hint"
    static let accessibilitySearchResults = "accessibility.search.results"
}
