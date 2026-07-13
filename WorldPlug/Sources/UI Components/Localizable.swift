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
        String(localized: String.LocalizationValue(self))
    }

    /// Returns a localized version of the string with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: String(localized: String.LocalizationValue(self)), arguments: arguments)
    }

    /// Returns a localized version of the string from a specific table
    func localized(from table: StringCatalog) -> String {
        String(localized: String.LocalizationValue(self), table: table.rawValue)
    }

    /// Returns a localized version of the string from a specific table with format arguments
    func localized(from table: StringCatalog, _ arguments: CVarArg...) -> String {
        String(format: String(localized: String.LocalizationValue(self), table: table.rawValue), arguments: arguments)
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
    static let countriesFilterAll = "countries.filter.all"
    static let countriesFilterEmptyTitle = "countries.filter.empty.title"
    static let countriesFilterEmptyDescription = "countries.filter.empty.description"
    static let countriesFilterTip = "countries.filter.tip"
    static let countryDetailPlugsInUse = "country.detail.plugs.in.use"
    static let countryDetailDirectlyCompatible = "country.detail.directly.compatible"
    static let countryDetailNoCompatiblePlugs = "country.detail.no.compatible.plugs"
    static let countryDetailElectricalSetup = "country.detail.electrical.setup"
    static let countryDetailCompatibilityOverview = "country.detail.compatibility.overview"
    static let countryDetailAllPlugs = "country.detail.all.plugs"
    static let countryDetailMapLocating = "country.detail.map.locating"
    static let countryDetailExpand = "country.detail.expand"
    static let countryDetailCollapse = "country.detail.collapse"
    static let searchCountriesPlaceholder = "search.countries.placeholder"

    // MARK: - Country Card

    static let compatiblePlugs = "compatible.plugs"
    static let plugTypePrefix = "plug.type.prefix"
    static let plugType = "plug.type"

    // MARK: - Plug Detail View

    static let plugOverview = "plug.overview"
    static let plugSpecifications = "plug.specifications"
    static let plugImages = "plug.images"
    static let pinSpacing = "pin.spacing"
    static let pinDiameter = "pin.diameter"
    static let ratedAmperage = "rated.amperage"
    static let alsoKnownAs = "also.known.as"

    // MARK: - Plug Type Descriptions

    static let plugTypeADescription = "plug.type.a.description"
    static let plugTypeBDescription = "plug.type.b.description"
    static let plugTypeCDescription = "plug.type.c.description"
    static let plugTypeDDescription = "plug.type.d.description"
    static let plugTypeEDescription = "plug.type.e.description"
    static let plugTypeFDescription = "plug.type.f.description"
    static let plugTypeGDescription = "plug.type.g.description"
    static let plugTypeHDescription = "plug.type.h.description"
    static let plugTypeIDescription = "plug.type.i.description"
    static let plugTypeJDescription = "plug.type.j.description"
    static let plugTypeKDescription = "plug.type.k.description"
    static let plugTypeLDescription = "plug.type.l.description"
    static let plugTypeMDescription = "plug.type.m.description"
    static let plugTypeNDescription = "plug.type.n.description"
    static let plugTypeODescription = "plug.type.o.description"

    static let plugShare = "plug.share"
    static let plugShareTagline = "plug.share.tagline"
    static let plugShareText = "plug.share.text"

    // MARK: - Home Country

    static let homeCountryBadge = "home.country.badge"
    static let homeCountrySet = "home.country.set"
    static let homeCountryRemove = "home.country.remove"
    static let homeCountryCompatible = "home.country.compatible"
    static let homeCountryAdapterNeeded = "home.country.adapter.needed"
    static let homeCountryComparingWith = "home.country.comparing.with"

    // MARK: - Compatibility Legend

    static let compatibilityLegendTitle = "compatibility.legend.title"
    static let compatibilityLegendCompatibleTitle = "compatibility.legend.compatible.title"
    static let compatibilityLegendCompatibleDesc = "compatibility.legend.compatible.desc"
    static let compatibilityLegendAdapterTitle = "compatibility.legend.adapter.title"
    static let compatibilityLegendAdapterDesc = "compatibility.legend.adapter.desc"
    static let compatibilityLegendConverterTitle = "compatibility.legend.converter.title"
    static let compatibilityLegendConverterDesc = "compatibility.legend.converter.desc"

    // MARK: - General

    static let loading = "loading"
    static let error = "error"
    static let retry = "retry"

    // MARK: - Accessibility

    static let accessibilityPlugCompatible = "accessibility.plug.compatible"
    static let accessibilityPlugAdapterNeeded = "accessibility.plug.adapter.needed"
    static let accessibilityPlugConverterRequired = "accessibility.plug.converter.required"
    static let accessibilityCompatibilityLegend = "accessibility.compatibility.legend"
    static let accessibilityHomeCountryBadge = "accessibility.home.country.badge"
    static let accessibilityVoltage = "accessibility.voltage"
    static let accessibilityFrequency = "accessibility.frequency"
    static let accessibilityPlugTypesCount = "accessibility.plug.types.count"
    static let accessibilityCompatiblePlugTypes = "accessibility.compatible.plug.types"
    static let accessibilityPlugTypeLabel = "accessibility.plug.type.label"
    static let accessibilityPlugTypeHint = "accessibility.plug.type.hint"
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
