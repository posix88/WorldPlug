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

    // MARK: - Onboarding

    static let onboardingTagline = "onboarding.tagline"
    static let onboardingCountriesTitle = "onboarding.countries.title"
    static let onboardingCountriesSubtitle = "onboarding.countries.subtitle"
    static let onboardingHomeCountryTitle = "onboarding.home.country.title"
    static let onboardingHomeCountrySubtitle = "onboarding.home.country.subtitle"
    static let onboardingAdapterInfoTitle = "onboarding.adapter.info.title"
    static let onboardingAdapterInfoSubtitle = "onboarding.adapter.info.subtitle"
    static let onboardingGetStarted = "onboarding.get.started"
    static let onboardingPickerTitle = "onboarding.picker.title"
    static let onboardingPickerSubtitle = "onboarding.picker.subtitle"
    static let onboardingSearchPlaceholder = "onboarding.search.placeholder"
    static let onboardingSelectCountry = "onboarding.select.country"

    // MARK: - Saved Countries

    static let savedCountriesTitle = "saved.countries.title"
    static let savedCountriesEmptyTitle = "saved.countries.empty.title"
    static let savedCountriesEmptyDescription = "saved.countries.empty.description"
    static let savedCountriesFreeLimit = "saved.countries.free.limit"
    static let savedCountriesPremiumTitle = "saved.countries.premium.title"
    static let savedCountriesPremiumDescription = "saved.countries.premium.description"
    static let savedCountriesAdd = "saved.countries.add"
    static let savedCountriesRemove = "saved.countries.remove"
    static let savedCountriesPreviewTitle = "saved.countries.preview.title"

    // MARK: - Premium Paywall

    static let premiumPaywallTitle = "premium.paywall.title"
    static let premiumPaywallMessage = "premium.paywall.message"
    static let premiumPaywallCountrySaveMessage = "premium.paywall.country.save.message"
    static let premiumPaywallPurchase = "premium.paywall.purchase"
    static let premiumPaywallPurchaseWithPrice = "premium.paywall.purchase.with.price"
    static let premiumPaywallRestore = "premium.paywall.restore"
    static let premiumPaywallBenefitSavedCountries = "premium.paywall.benefit.saved.countries"
    static let premiumPaywallBenefitNextTrip = "premium.paywall.benefit.next.trip"
    static let premiumPaywallBenefitWidgets = "premium.paywall.benefit.widgets"
    static let premiumPaywallErrorTitle = "premium.paywall.error.title"
    static let premiumPaywallDismiss = "premium.paywall.dismiss"
    static let premiumPaywallPendingTitle = "premium.paywall.pending.title"
    static let premiumPaywallPendingMessage = "premium.paywall.pending.message"

    // MARK: - Trip Check

    static let tripCheckUnlimited = "trip.check.unlimited"
    static let tripCheckUnlock = "trip.check.unlock"
    static let tripCheckDevices = "trip.check.devices"
    static let tripCheckDevicesEmpty = "trip.check.devices.empty"
    static let tripCheckAddDevice = "trip.check.add.device"
    static let tripCheckRemoveDevice = "trip.check.remove.device"
    static let tripCheckDeviceDetails = "trip.check.device.details"
    static let tripCheckDeviceName = "trip.check.device.name"
    static let tripCheckDeviceIcon = "trip.check.device.icon"
    static let tripCheckDeviceChooseIcon = "trip.check.device.choose.icon"
    static let tripCheckDeviceIconPlug = "trip.check.device.icon.plug"
    static let tripCheckDeviceIconOther = "trip.check.device.icon.other"
    static let tripCheckDeviceVoltage = "trip.check.device.voltage"
    static let tripCheckDeviceFrequency = "trip.check.device.frequency"
    static let tripCheckScanLabel = "trip.check.scan.label"
    static let tripCheckScanLabelHint = "trip.check.scan.label.hint"
    static let tripCheckScanAnalyze = "trip.check.scan.analyze"
    static let tripCheckScanSmartHint = "trip.check.scan.smart.hint"
    static let tripCheckScanNoValues = "trip.check.scan.no.values"
    static let tripCheckScanUnavailable = "trip.check.scan.unavailable"
    static let tripCheckScanUnavailableDescription = "trip.check.scan.unavailable.description"
    static let tripCheckDestination = "trip.check.destination"
    static let tripCheckCountry = "trip.check.country"
    static let tripCheckDeviceSection = "trip.check.device.section"
    static let tripCheckCancel = "trip.check.cancel"
    static let tripCheckAction = "trip.check.action"
    static let tripCheckSafetySection = "trip.check.safety.section"
    static let tripCheckUnavailable = "trip.check.unavailable"
    static let tripCheckDisclaimer = "trip.check.disclaimer"
    static let tripCheckDisclaimerTitle = "trip.check.disclaimer.title"
    static let tripCheckDisclaimerSummary = "trip.check.disclaimer.summary"
    static let tripCheckDevicePhone = "trip.check.device.phone"
    static let tripCheckDeviceLaptop = "trip.check.device.laptop"
    static let tripCheckDeviceCamera = "trip.check.device.camera"
    static let tripCheckDeviceHeadphones = "trip.check.device.headphones"
    static let tripCheckDeviceSpeaker = "trip.check.device.speaker"
    static let tripCheckDeviceGameController = "trip.check.device.game.controller"
    static let tripCheckDeviceSmartwatch = "trip.check.device.smartwatch"
    static let tripCheckDeviceShaver = "trip.check.device.shaver"
    static let tripCheckDeviceHairDryer = "trip.check.device.hair.dryer"
    static let tripCheckDeviceHairStyler = "trip.check.device.hair.styler"
    static let tripCheckDeviceCPAP = "trip.check.device.cpap"
    static let tripCheckStatusReady = "trip.check.status.ready"
    static let tripCheckStatusAdapter = "trip.check.status.adapter"
    static let tripCheckStatusHomeCountry = "trip.check.status.home.country"
    static let tripCheckStatusCheckLabel = "trip.check.status.check.label"
    static let tripCheckStatusUnsafe = "trip.check.status.unsafe"
    static let intentCountryEntityElectricalInformation = "intent.country.entity.electrical.information"
    static let intentCountryEntityPlugTypes = "intent.country.entity.plug.types"
    static let intentCountryEntityPlugTypesUnavailable = "intent.country.entity.plug.types.unavailable"
    static let tripCheckMessageSetHome = "trip.check.message.set.home"
    static let tripCheckMessageReady = "trip.check.message.ready"
    static let tripCheckMessageDualVoltage = "trip.check.message.dual.voltage"
    static let tripCheckMessageAdapter = "trip.check.message.adapter"
    static let tripCheckMessageUnsafe = "trip.check.message.unsafe"
    static let tripCheckMessageMissingVoltage = "trip.check.message.missing.voltage"
    static let tripCheckMessageFrequency = "trip.check.message.frequency"

    // MARK: - Trips

    // The `next.trip.*` string keys are kept as-is: their copy ("Dates", "Departure",
    // "Return date", "Trip name", "Destination") is still exactly right, and a string key is an
    // internal identifier the user never sees — same reasoning as the "Voltly" naming policy.
    static let tripsTabTitle = "trips.tab.title"
    static let tripsTitle = "trips.title"
    static let tripsAdd = "trips.add"
    static let tripsEmptyTitle = "trips.empty.title"
    static let tripsEmptyDescription = "trips.empty.description"
    static let tripsIntroduction = "trips.introduction"
    static let tripsSectionUpcoming = "trips.section.upcoming"
    static let tripsSectionPast = "trips.section.past"
    static let tripsBadgeNext = "trips.badge.next"
    static let tripsRowNoDevices = "trips.row.no.devices"
    static let tripDestination = "next.trip.destination"
    static let tripDates = "next.trip.dates"
    static let tripDeparture = "next.trip.departure"
    static let tripReturnDate = "next.trip.return.date"
    static let tripName = "next.trip.name"
    static let tripNamePlaceholder = "next.trip.name.placeholder"
    static let tripSearchDestination = "next.trip.search.destination"
    static let tripRemove = "trip.remove"
    static let tripEditorNewTitle = "trip.editor.new.title"
    static let tripEditorEditTitle = "trip.editor.edit.title"
    static let tripEditorDestinationPlaceholder = "trip.editor.destination.placeholder"
    static let tripDetailEdit = "trip.detail.edit"
    static let tripDetailDevicesEmptyTitle = "trip.detail.devices.empty.title"
    static let tripDetailDevicesEmptyDescription = "trip.detail.devices.empty.description"

    // MARK: - Settings

    static let settingsTitle = "settings.title"
    static let settingsOpen = "settings.open"
    static let settingsDone = "settings.done"
    static let settingsSectionTravel = "settings.section.travel"
    static let settingsSectionWidgets = "settings.section.widgets"
    static let settingsSectionPremium = "settings.section.premium"
    static let settingsSectionAbout = "settings.section.about"
    static let settingsHomeCountry = "settings.home.country"
    static let settingsHomeCountryNone = "settings.home.country.none"
    static let settingsHomeCountryFooter = "settings.home.country.footer"
    static let settingsHomeCountryClear = "settings.home.country.clear"
    static let settingsFavoriteWidgetFooter = "settings.favorite.widget.footer"
    static let settingsFavoriteWidgetNeedsSaved = "settings.favorite.widget.needs.saved"
    static let settingsPremiumActive = "settings.premium.active"
    static let settingsPremiumActiveFooter = "settings.premium.active.footer"
    static let settingsPremiumInactive = "settings.premium.inactive"
    static let settingsRestoreFailed = "settings.restore.failed"
    static let settingsVersion = "settings.version"
    static let settingsRate = "settings.rate"
    static let settingsShare = "settings.share"
    static let settingsShareText = "settings.share.text"
    static let settingsDebug = "settings.debug"
    static let settingsDebugSeededData = "settings.debug.seeded.data"

    // MARK: - Favorite Widget

    static let favoriteWidgetTitle = "favorite.widget.title"
    static let favoriteWidgetNoSelection = "favorite.widget.no.selection"
    static let favoriteWidgetTipTitle = "favorite.widget.tip.title"
    static let favoriteWidgetTipMessage = "favorite.widget.tip.message"

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
    static let countryDetailMapUnavailable = "country.detail.map.unavailable"
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
    static let plugTypeUnknownShortInfo = "plug.type.unknown.short.info"

    static let plugShare = "plug.share"
    static let plugShareTagline = "plug.share.tagline"
    static let plugShareText = "plug.share.text"

    // MARK: - Home Country

    static let homeCountryBadge = "home.country.badge"
    static let homeCountrySet = "home.country.set"
    static let homeCountryRemove = "home.country.remove"
    static let homeCountryUpdate = "home.country.update"
    static let homeCountryCompatible = "home.country.compatible"
    static let homeCountryAdapterNeeded = "home.country.adapter.needed"
    static let homeCountryComparingWith = "home.country.comparing.with"
    static let homeCountryRemoveConfirmationTitle = "home.country.remove.confirmation.title"
    static let homeCountryRemoveConfirmationMessage = "home.country.remove.confirmation.message"
    static let homeCountryUpdateConfirmationTitle = "home.country.update.confirmation.title"
    static let homeCountryUpdateConfirmationMessage = "home.country.update.confirmation.message"

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
    static let generalCancel = "general.cancel"
    static let generalClose = "general.close"
    static let navigationBack = "navigation.back"

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
