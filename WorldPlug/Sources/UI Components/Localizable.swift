//
//  Localizable.swift
//  WorldPlug
//

import Foundation

// MARK: - StringCatalog

enum StringCatalog: String {
    case main = "Localizable"
    case accessibility = "Accessibility"
}

// MARK: - LocalizedStringResource + formatting

extension LocalizedStringResource {
    /// Resolves this resource to a `String`, substituting positional format arguments.
    ///
    /// Needed because this project uses *opaque* keys (`"plug.type.prefix"`) whose catalog
    /// *values* carry the `%@` placeholders. `LocalizedStringResource` interpolation builds the
    /// key out of the interpolated text, so `LocalizedStringResource("Type \(id)")` would look up
    /// `"Type %@"` and miss the entry entirely — a format pass is unavoidable with this key style.
    ///
    /// Passing `locale:` is the part that matters: `String(format:)` without it renders numbers as
    /// ASCII 0-9 regardless of the user's locale, which is wrong for user-facing text.
    func string(_ arguments: CVarArg...) -> String {
        String(format: String(localized: self), locale: .autoupdatingCurrent, arguments: arguments)
    }
}

// MARK: - LocalizationKeys

/// Centralised localized text.
///
/// Typed `LocalizedStringResource`, not `String`. A `String` has to be resolved the moment it is
/// created, which loses the `\.locale` environment override (previews, per-view injection) and
/// leaves translators no `comment:` hook. A resource defers resolution to the display site, so the
/// same value renders correctly wherever and whenever it is finally shown — including from model
/// and view-model types, which is why `DeviceSafetyStatus.title` and friends can carry text
/// without freezing a language into it.
enum LocalizationKeys {
    // MARK: - Main Navigation

    static let appTitle = LocalizedStringResource("app.title")

    // MARK: - Onboarding

    static let onboardingTagline = LocalizedStringResource("onboarding.tagline")
    static let onboardingCountriesTitle = LocalizedStringResource("onboarding.countries.title")
    static let onboardingCountriesSubtitle = LocalizedStringResource("onboarding.countries.subtitle")
    static let onboardingHomeCountryTitle = LocalizedStringResource("onboarding.home.country.title")
    static let onboardingHomeCountrySubtitle = LocalizedStringResource("onboarding.home.country.subtitle")
    static let onboardingAdapterInfoTitle = LocalizedStringResource("onboarding.adapter.info.title")
    static let onboardingAdapterInfoSubtitle = LocalizedStringResource("onboarding.adapter.info.subtitle")
    static let onboardingGetStarted = LocalizedStringResource("onboarding.get.started")
    static let onboardingPickerTitle = LocalizedStringResource("onboarding.picker.title")
    static let onboardingPickerSubtitle = LocalizedStringResource("onboarding.picker.subtitle")
    static let onboardingSearchPlaceholder = LocalizedStringResource("onboarding.search.placeholder")
    static let onboardingSelectCountry = LocalizedStringResource("onboarding.select.country")

    // MARK: - Saved Countries

    static let savedCountriesTitle = LocalizedStringResource("saved.countries.title")
    static let savedCountriesEmptyTitle = LocalizedStringResource("saved.countries.empty.title")
    static let savedCountriesEmptyDescription = LocalizedStringResource("saved.countries.empty.description")
    static let savedCountriesFreeLimit = LocalizedStringResource("saved.countries.free.limit")
    static let savedCountriesPremiumTitle = LocalizedStringResource("saved.countries.premium.title")
    static let savedCountriesPremiumDescription = LocalizedStringResource("saved.countries.premium.description")
    static let savedCountriesAdd = LocalizedStringResource("saved.countries.add")
    static let savedCountriesRemove = LocalizedStringResource("saved.countries.remove")
    static let savedCountriesPreviewTitle = LocalizedStringResource("saved.countries.preview.title")

    // MARK: - Premium Paywall

    static let premiumPaywallTitle = LocalizedStringResource("premium.paywall.title")
    static let premiumPaywallMessage = LocalizedStringResource("premium.paywall.message")
    static let premiumPaywallCountrySaveMessage = LocalizedStringResource("premium.paywall.country.save.message")
    static let premiumPaywallPurchase = LocalizedStringResource("premium.paywall.purchase")
    static let premiumPaywallPurchaseWithPrice = LocalizedStringResource("premium.paywall.purchase.with.price")
    static let premiumPaywallRedeemCode = LocalizedStringResource("premium.paywall.redeem.code")
    static let premiumPaywallRestore = LocalizedStringResource("premium.paywall.restore")
    static let premiumPaywallBenefitSavedCountries = LocalizedStringResource("premium.paywall.benefit.saved.countries")
    static let premiumPaywallBenefitNextTrip = LocalizedStringResource("premium.paywall.benefit.next.trip")
    static let premiumPaywallBenefitWidgets = LocalizedStringResource("premium.paywall.benefit.widgets")
    static let premiumPaywallErrorTitle = LocalizedStringResource("premium.paywall.error.title")
    static let premiumPaywallDismiss = LocalizedStringResource("premium.paywall.dismiss")
    static let premiumPaywallPendingTitle = LocalizedStringResource("premium.paywall.pending.title")
    static let premiumPaywallPendingMessage = LocalizedStringResource("premium.paywall.pending.message")

    // MARK: - Trip Check

    static let tripCheckUnlimited = LocalizedStringResource("trip.check.unlimited")
    static let tripCheckUnlock = LocalizedStringResource("trip.check.unlock")
    static let tripCheckDevices = LocalizedStringResource("trip.check.devices")
    static let tripCheckDevicesEmpty = LocalizedStringResource("trip.check.devices.empty")
    static let tripCheckAddDevice = LocalizedStringResource("trip.check.add.device")
    static let tripCheckRemoveDevice = LocalizedStringResource("trip.check.remove.device")
    static let tripCheckDeviceDetails = LocalizedStringResource("trip.check.device.details")
    static let tripCheckDeviceName = LocalizedStringResource("trip.check.device.name")
    static let tripCheckDeviceIcon = LocalizedStringResource("trip.check.device.icon")
    static let tripCheckDeviceChooseIcon = LocalizedStringResource("trip.check.device.choose.icon")
    static let tripCheckDeviceIconPlug = LocalizedStringResource("trip.check.device.icon.plug")
    static let tripCheckDeviceIconOther = LocalizedStringResource("trip.check.device.icon.other")
    static let tripCheckDeviceVoltage = LocalizedStringResource("trip.check.device.voltage")
    static let tripCheckDeviceFrequency = LocalizedStringResource("trip.check.device.frequency")
    static let tripCheckScanLabel = LocalizedStringResource("trip.check.scan.label")
    static let tripCheckScanLabelHint = LocalizedStringResource("trip.check.scan.label.hint")
    static let tripCheckScanAnalyze = LocalizedStringResource("trip.check.scan.analyze")
    static let tripCheckScanSmartHint = LocalizedStringResource("trip.check.scan.smart.hint")
    static let tripCheckScanNoValues = LocalizedStringResource("trip.check.scan.no.values")
    static let tripCheckScanUnavailable = LocalizedStringResource("trip.check.scan.unavailable")
    static let tripCheckScanUnavailableDescription = LocalizedStringResource("trip.check.scan.unavailable.description")
    static let tripCheckDestination = LocalizedStringResource("trip.check.destination")
    static let tripCheckCountry = LocalizedStringResource("trip.check.country")
    static let tripCheckDeviceSection = LocalizedStringResource("trip.check.device.section")
    static let tripCheckCancel = LocalizedStringResource("trip.check.cancel")
    static let tripCheckAction = LocalizedStringResource("trip.check.action")
    static let tripCheckSafetySection = LocalizedStringResource("trip.check.safety.section")
    static let tripCheckUnavailable = LocalizedStringResource("trip.check.unavailable")
    static let tripCheckDisclaimer = LocalizedStringResource("trip.check.disclaimer")
    static let tripCheckDisclaimerTitle = LocalizedStringResource("trip.check.disclaimer.title")
    static let tripCheckDisclaimerSummary = LocalizedStringResource("trip.check.disclaimer.summary")
    static let tripCheckDevicePhone = LocalizedStringResource("trip.check.device.phone")
    static let tripCheckDeviceLaptop = LocalizedStringResource("trip.check.device.laptop")
    static let tripCheckDeviceCamera = LocalizedStringResource("trip.check.device.camera")
    static let tripCheckDeviceHeadphones = LocalizedStringResource("trip.check.device.headphones")
    static let tripCheckDeviceSpeaker = LocalizedStringResource("trip.check.device.speaker")
    static let tripCheckDeviceGameController = LocalizedStringResource("trip.check.device.game.controller")
    static let tripCheckDeviceSmartwatch = LocalizedStringResource("trip.check.device.smartwatch")
    static let tripCheckDeviceShaver = LocalizedStringResource("trip.check.device.shaver")
    static let tripCheckDeviceHairDryer = LocalizedStringResource("trip.check.device.hair.dryer")
    static let tripCheckDeviceHairStyler = LocalizedStringResource("trip.check.device.hair.styler")
    static let tripCheckDeviceCPAP = LocalizedStringResource("trip.check.device.cpap")
    static let tripCheckStatusReady = LocalizedStringResource("trip.check.status.ready")
    static let tripCheckStatusAdapter = LocalizedStringResource("trip.check.status.adapter")
    static let tripCheckStatusHomeCountry = LocalizedStringResource("trip.check.status.home.country")
    static let tripCheckStatusCheckLabel = LocalizedStringResource("trip.check.status.check.label")
    static let tripCheckStatusUnsafe = LocalizedStringResource("trip.check.status.unsafe")
    static let intentCountryEntityElectricalInformation = LocalizedStringResource("intent.country.entity.electrical.information")
    static let intentCountryEntityPlugTypes = LocalizedStringResource("intent.country.entity.plug.types")
    static let intentCountryEntityPlugTypesUnavailable = LocalizedStringResource("intent.country.entity.plug.types.unavailable")
    static let tripCheckMessageSetHome = LocalizedStringResource("trip.check.message.set.home")
    static let tripCheckMessageReady = LocalizedStringResource("trip.check.message.ready")
    static let tripCheckMessageDualVoltage = LocalizedStringResource("trip.check.message.dual.voltage")
    static let tripCheckMessageAdapter = LocalizedStringResource("trip.check.message.adapter")
    static let tripCheckMessageUnsafe = LocalizedStringResource("trip.check.message.unsafe")
    static let tripCheckMessageMissingVoltage = LocalizedStringResource("trip.check.message.missing.voltage")
    static let tripCheckMessageFrequency = LocalizedStringResource("trip.check.message.frequency")

    // MARK: - Trips

    // The `next.trip.*` string keys are kept as-is: their copy ("Dates", "Departure",
    // "Return date", "Trip name", "Destination") is still exactly right, and a string key is an
    // internal identifier the user never sees — same reasoning as the "Voltly" naming policy.
    static let tripsTabTitle = LocalizedStringResource("trips.tab.title")
    static let tripsTitle = LocalizedStringResource("trips.title")
    static let tripsAdd = LocalizedStringResource("trips.add")
    static let tripsEmptyTitle = LocalizedStringResource("trips.empty.title")
    static let tripsEmptyDescription = LocalizedStringResource("trips.empty.description")
    static let tripsIntroduction = LocalizedStringResource("trips.introduction")
    static let tripsSectionUpcoming = LocalizedStringResource("trips.section.upcoming")
    static let tripsSectionPast = LocalizedStringResource("trips.section.past")
    /// Value is already uppercase in every locale. Was `"Next"` + `.textCase(.uppercase)`, which
    /// forces one casing decision on all translations and mangles scripts where an all-caps
    /// transform is wrong (Turkish dotless i, German ß).
    static let tripsBadgeNext = LocalizedStringResource("trips.badge.next")
    /// Uppercase display labels for the trip metric tiles. Separate from the
    /// `accessibility.voltage`/`.frequency` pair, which VoiceOver also reads — uppercasing those
    /// would make the screen reader shout.
    static let tripMetricVoltage = LocalizedStringResource("trip.metric.voltage")
    static let tripMetricFrequency = LocalizedStringResource("trip.metric.frequency")
    static let tripsRowNoDevices = LocalizedStringResource("trips.row.no.devices")
    static let tripDestination = LocalizedStringResource("next.trip.destination")
    static let tripDates = LocalizedStringResource("next.trip.dates")
    static let tripDeparture = LocalizedStringResource("next.trip.departure")
    static let tripReturnDate = LocalizedStringResource("next.trip.return.date")
    static let tripName = LocalizedStringResource("next.trip.name")
    static let tripNamePlaceholder = LocalizedStringResource("next.trip.name.placeholder")
    static let tripSearchDestination = LocalizedStringResource("next.trip.search.destination")
    static let tripRemove = LocalizedStringResource("trip.remove")
    static let tripEditorNewTitle = LocalizedStringResource("trip.editor.new.title")
    static let tripEditorEditTitle = LocalizedStringResource("trip.editor.edit.title")
    static let tripEditorDestinationPlaceholder = LocalizedStringResource("trip.editor.destination.placeholder")
    static let tripDetailEdit = LocalizedStringResource("trip.detail.edit")
    static let tripDetailEditDeviceHint = LocalizedStringResource("trip.detail.edit.device.hint")
    static let tripDetailDevicesEmptyTitle = LocalizedStringResource("trip.detail.devices.empty.title")
    static let tripDetailDevicesEmptyDescription = LocalizedStringResource("trip.detail.devices.empty.description")

    // MARK: - Settings

    static let settingsTitle = LocalizedStringResource("settings.title")
    static let settingsOpen = LocalizedStringResource("settings.open")
    static let settingsDone = LocalizedStringResource("settings.done")
    static let settingsSectionTravel = LocalizedStringResource("settings.section.travel")
    static let settingsSectionWidgets = LocalizedStringResource("settings.section.widgets")
    static let settingsSectionPremium = LocalizedStringResource("settings.section.premium")
    static let settingsSectionAbout = LocalizedStringResource("settings.section.about")
    static let settingsHomeCountry = LocalizedStringResource("settings.home.country")
    static let settingsHomeCountryNone = LocalizedStringResource("settings.home.country.none")
    static let settingsHomeCountryFooter = LocalizedStringResource("settings.home.country.footer")
    static let settingsHomeCountryClear = LocalizedStringResource("settings.home.country.clear")
    static let settingsFavoriteWidgetFooter = LocalizedStringResource("settings.favorite.widget.footer")
    static let settingsFavoriteWidgetNeedsSaved = LocalizedStringResource("settings.favorite.widget.needs.saved")
    static let settingsPremiumActive = LocalizedStringResource("settings.premium.active")
    static let settingsPremiumActiveFooter = LocalizedStringResource("settings.premium.active.footer")
    static let settingsPremiumInactive = LocalizedStringResource("settings.premium.inactive")
    static let settingsRestoreFailed = LocalizedStringResource("settings.restore.failed")
    static let settingsVersion = LocalizedStringResource("settings.version")
    static let settingsRate = LocalizedStringResource("settings.rate")
    static let settingsShare = LocalizedStringResource("settings.share")
    static let settingsShareText = LocalizedStringResource("settings.share.text")
    static let settingsDebug = LocalizedStringResource("settings.debug")
    static let settingsDebugSeededData = LocalizedStringResource("settings.debug.seeded.data")

    // MARK: - Favorite Widget

    static let favoriteWidgetTitle = LocalizedStringResource("favorite.widget.title")
    static let favoriteWidgetNoSelection = LocalizedStringResource("favorite.widget.no.selection")
    static let favoriteWidgetTipTitle = LocalizedStringResource("favorite.widget.tip.title")
    static let favoriteWidgetTipMessage = LocalizedStringResource("favorite.widget.tip.message")

    // MARK: - Countries List View

    static let countriesTitle = LocalizedStringResource("countries.title")
    static let countriesAvailable = LocalizedStringResource("countries.available")
    static let countriesFilterAll = LocalizedStringResource("countries.filter.all")
    static let countriesFilterEmptyTitle = LocalizedStringResource("countries.filter.empty.title")
    static let countriesFilterEmptyDescription = LocalizedStringResource("countries.filter.empty.description")
    static let countriesFilterTip = LocalizedStringResource("countries.filter.tip")
    static let countryDetailPlugsInUse = LocalizedStringResource("country.detail.plugs.in.use")
    static let countryDetailDirectlyCompatible = LocalizedStringResource("country.detail.directly.compatible")
    static let countryDetailNoCompatiblePlugs = LocalizedStringResource("country.detail.no.compatible.plugs")
    static let countryDetailElectricalSetup = LocalizedStringResource("country.detail.electrical.setup")
    static let countryDetailCompatibilityOverview = LocalizedStringResource("country.detail.compatibility.overview")
    static let countryDetailAllPlugs = LocalizedStringResource("country.detail.all.plugs")
    static let countryDetailMapLocating = LocalizedStringResource("country.detail.map.locating")
    static let countryDetailMapUnavailable = LocalizedStringResource("country.detail.map.unavailable")
    static let countryDetailExpand = LocalizedStringResource("country.detail.expand")
    static let countryDetailCollapse = LocalizedStringResource("country.detail.collapse")
    static let searchCountriesPlaceholder = LocalizedStringResource("search.countries.placeholder")

    // MARK: - Country Card

    static let compatiblePlugs = LocalizedStringResource("compatible.plugs")
    static let plugTypePrefix = LocalizedStringResource("plug.type.prefix")
    static let plugType = LocalizedStringResource("plug.type")

    // MARK: - Plug Detail View

    static let plugOverview = LocalizedStringResource("plug.overview")
    static let plugSpecifications = LocalizedStringResource("plug.specifications")
    static let plugImages = LocalizedStringResource("plug.images")
    static let pinSpacing = LocalizedStringResource("pin.spacing")
    static let pinDiameter = LocalizedStringResource("pin.diameter")
    static let ratedAmperage = LocalizedStringResource("rated.amperage")
    static let alsoKnownAs = LocalizedStringResource("also.known.as")

    // MARK: - Plug Type Descriptions

    static let plugTypeADescription = LocalizedStringResource("plug.type.a.description")
    static let plugTypeBDescription = LocalizedStringResource("plug.type.b.description")
    static let plugTypeCDescription = LocalizedStringResource("plug.type.c.description")
    static let plugTypeDDescription = LocalizedStringResource("plug.type.d.description")
    static let plugTypeEDescription = LocalizedStringResource("plug.type.e.description")
    static let plugTypeFDescription = LocalizedStringResource("plug.type.f.description")
    static let plugTypeGDescription = LocalizedStringResource("plug.type.g.description")
    static let plugTypeHDescription = LocalizedStringResource("plug.type.h.description")
    static let plugTypeIDescription = LocalizedStringResource("plug.type.i.description")
    static let plugTypeJDescription = LocalizedStringResource("plug.type.j.description")
    static let plugTypeKDescription = LocalizedStringResource("plug.type.k.description")
    static let plugTypeLDescription = LocalizedStringResource("plug.type.l.description")
    static let plugTypeMDescription = LocalizedStringResource("plug.type.m.description")
    static let plugTypeNDescription = LocalizedStringResource("plug.type.n.description")
    static let plugTypeODescription = LocalizedStringResource("plug.type.o.description")
    static let plugTypeUnknownShortInfo = LocalizedStringResource("plug.type.unknown.short.info")

    static let plugShare = LocalizedStringResource("plug.share")
    static let plugShareTagline = LocalizedStringResource("plug.share.tagline")
    static let plugShareText = LocalizedStringResource("plug.share.text")

    // MARK: - Home Country

    static let homeCountryBadge = LocalizedStringResource("home.country.badge")
    static let homeCountryChange = LocalizedStringResource("home.country.change")
    static let homeCountrySet = LocalizedStringResource("home.country.set")
    static let homeCountrySetupTitle = LocalizedStringResource("home.country.setup.title")
    static let homeCountrySetupDescription = LocalizedStringResource("home.country.setup.description")
    static let homeCountryRemove = LocalizedStringResource("home.country.remove")
    static let homeCountryUpdate = LocalizedStringResource("home.country.update")
    static let homeCountryCompatible = LocalizedStringResource("home.country.compatible")
    static let homeCountryAdapterNeeded = LocalizedStringResource("home.country.adapter.needed")
    static let homeCountryComparingWith = LocalizedStringResource("home.country.comparing.with")
    static let homeCountryRemoveConfirmationTitle = LocalizedStringResource("home.country.remove.confirmation.title")
    static let homeCountryRemoveConfirmationMessage = LocalizedStringResource("home.country.remove.confirmation.message")
    static let homeCountryUpdateConfirmationTitle = LocalizedStringResource("home.country.update.confirmation.title")
    static let homeCountryUpdateConfirmationMessage = LocalizedStringResource("home.country.update.confirmation.message")

    // MARK: - Compatibility Legend

    static let compatibilityLegendTitle = LocalizedStringResource("compatibility.legend.title")
    static let compatibilityLegendCompatibleTitle = LocalizedStringResource("compatibility.legend.compatible.title")
    static let compatibilityLegendCompatibleDesc = LocalizedStringResource("compatibility.legend.compatible.desc")
    static let compatibilityLegendAdapterTitle = LocalizedStringResource("compatibility.legend.adapter.title")
    static let compatibilityLegendAdapterDesc = LocalizedStringResource("compatibility.legend.adapter.desc")
    static let compatibilityLegendConverterTitle = LocalizedStringResource("compatibility.legend.converter.title")
    static let compatibilityLegendConverterDesc = LocalizedStringResource("compatibility.legend.converter.desc")
    /// A compatibility group heading and how many plugs are in it. Was assembled inline as
    /// `"\(title) (\(count))"`, which made the format string itself a catalog key and left
    /// translators no way to move the count.
    static let compatibilityGroupCount = LocalizedStringResource("compatibility.group.count")

    // MARK: - General

    static let loading = LocalizedStringResource("loading")
    static let error = LocalizedStringResource("error")
    static let retry = LocalizedStringResource("retry")
    static let generalCancel = LocalizedStringResource("general.cancel")
    static let generalClose = LocalizedStringResource("general.close")
    static let navigationBack = LocalizedStringResource("navigation.back")

    // MARK: - Accessibility

    static let accessibilityPlugCompatible = LocalizedStringResource("accessibility.plug.compatible")
    static let accessibilityPlugAdapterNeeded = LocalizedStringResource("accessibility.plug.adapter.needed")
    static let accessibilityPlugConverterRequired = LocalizedStringResource("accessibility.plug.converter.required")
    static let accessibilityCompatibilityLegend = LocalizedStringResource("accessibility.compatibility.legend")
    static let accessibilityHomeCountryBadge = LocalizedStringResource("accessibility.home.country.badge")
    static let accessibilityVoltage = LocalizedStringResource(
        "accessibility.voltage",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityFrequency = LocalizedStringResource(
        "accessibility.frequency",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityPlugTypesCount = LocalizedStringResource("accessibility.plug.types.count")
    static let accessibilityCompatiblePlugTypes = LocalizedStringResource("accessibility.compatible.plug.types")
    static let accessibilityPlugTypeLabel = LocalizedStringResource("accessibility.plug.type.label")
    static let accessibilityPlugTypeHint = LocalizedStringResource("accessibility.plug.type.hint")
    static let accessibilityShowDetailsHint = LocalizedStringResource("accessibility.show.details.hint")
    static let accessibilityHideDetailsHint = LocalizedStringResource("accessibility.hide.details.hint")

    // MARK: - Countries List Accessibility

    static let accessibilityCountriesHeader = LocalizedStringResource("accessibility.countries.header")
    static let accessibilityCountriesList = LocalizedStringResource(
        "accessibility.countries.list",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityCountriesListDescription = LocalizedStringResource(
        "accessibility.countries.list.description",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityCountryAvailableCount = LocalizedStringResource("accessibility.country.available.count")
    static let accessibilityEmptyState = LocalizedStringResource(
        "accessibility.empty.state",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityEmptyStateDescription = LocalizedStringResource(
        "accessibility.empty.state.description",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilityNavigationTitle = LocalizedStringResource("accessibility.navigation.title")
    static let accessibilitySearchActive = LocalizedStringResource("accessibility.search.active")
    static let accessibilitySearchClear = LocalizedStringResource(
        "accessibility.search.clear",
        table: StringCatalog.accessibility.rawValue
    )
    static let accessibilitySearchField = LocalizedStringResource("accessibility.search.field")
    static let accessibilitySearchHint = LocalizedStringResource("accessibility.search.hint")
    static let accessibilitySearchResults = LocalizedStringResource(
        "accessibility.search.results",
        table: StringCatalog.accessibility.rawValue
    )
}
