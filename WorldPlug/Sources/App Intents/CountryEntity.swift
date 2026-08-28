import AppIntents
import CoreSpotlight
import Repository
import SwiftData

// MARK: - CountryEntity

/// A country that Voltly can resolve in Siri and the Shortcuts app.
struct CountryEntity: IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.country.entity.type",
            defaultValue: "Country"
        )
    )
    static let defaultQuery = CountryEntityQuery()

    let id: String
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.name",
            defaultValue: "Name"
        ),
        indexingKey: \.displayName
    )
    var name: String
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.code",
            defaultValue: "Code"
        ),
        indexingKey: \.country
    )
    var code: String
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.voltage",
            defaultValue: "Voltage"
        )
    )
    var voltage: String
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.frequency",
            defaultValue: "Frequency"
        )
    )
    var frequency: String
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.plug.types",
            defaultValue: "Plug types"
        ),
        indexingKey: \.keywords
    )
    var plugTypes: [String]
    @Property(
        title: LocalizedStringResource(
            "intent.country.property.electrical.information",
            defaultValue: "Electrical information"
        ),
        indexingKey: \.contentDescription
    )
    var electricalInformation: String
    var flag: String
    var localeIdentifier: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(flag) \(name)",
            subtitle: "\(voltage) · \(frequency) · \(formattedPlugTypes)",
            image: .init(systemName: "powerplug.fill")
        )
    }

    @MainActor
    init(country: Country, locale: Locale = .current) {
        self.id = country.code
        self.flag = country.flagUnicode
        self.localeIdentifier = locale.identifier
        self.name = country.localizedName(in: locale)
        self.code = country.code
        self.voltage = country.voltage
        self.frequency = country.frequency
        let plugTypes = country.sortedPlugs.map(\.id)
        self.plugTypes = plugTypes
        self.electricalInformation = Self.formatted(
            LocalizationKeys.intentCountryEntityElectricalInformation,
            locale: locale,
            country.localizedName(in: locale),
            country.voltage,
            country.frequency,
            Self.formattedPlugTypes(plugTypes, locale: locale)
        )
    }

    private var formattedPlugTypes: String {
        Self.formattedPlugTypes(plugTypes, locale: Locale(identifier: localeIdentifier))
    }

    private static func formattedPlugTypes(_ plugTypes: [String], locale: Locale) -> String {
        guard !plugTypes.isEmpty else {
            return localizedString(LocalizationKeys.intentCountryEntityPlugTypesUnavailable, locale: locale)
        }

        return formatted(
            LocalizationKeys.intentCountryEntityPlugTypes,
            locale: locale,
            plugTypes.formatted(.list(type: .and).locale(locale))
        )
    }

    private static func formatted(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(
            format: localizedString(key, locale: locale),
            locale: locale,
            arguments: arguments
        )
    }

    private static func localizedString(_ key: String, locale: Locale) -> String {
        let languageCode = locale.language.languageCode?.identifier
        let localizedBundle = languageCode
            .flatMap { Bundle.main.url(forResource: $0, withExtension: "lproj") }
            .flatMap { Bundle(url: $0) }
        return String(
            localized: String.LocalizationValue(key),
            bundle: localizedBundle ?? .main,
            locale: locale
        )
    }
}

// MARK: - CountryEntityQuery

struct CountryEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CountryEntity.ID]) async throws -> [CountryEntity] {
        let identifiers = Set(identifiers.map { $0.uppercased() })
        return await countryEntities { identifiers.contains($0.code) }
    }

    func entities(matching string: String) async throws -> [CountryEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return await countryEntities { country in
            country.code.localizedCaseInsensitiveContains(query) ||
                country.localizedName(in: .current).localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [CountryEntity] {
        await countryEntities { _ in true }
    }

    @available(iOS 27.0, *)
    func displayRepresentations(
        for identifiers: [CountryEntity.ID]
    ) async throws -> [CountryEntity.ID: DisplayRepresentation] {
        let entities = try await entities(for: identifiers)
        return Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0.displayRepresentation) })
    }

    @MainActor
    private func countryEntities(
        locale: Locale = .current,
        matching predicate: (Country) -> Bool
    ) -> [CountryEntity] {
        let descriptor = FetchDescriptor<Country>()
        let countries = (try? Repository.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        return countries
            .filter(predicate)
            .sortedByLocalizedName(in: locale)
            .map { CountryEntity(country: $0, locale: locale) }
    }
}

// MARK: IndexedEntityQuery

@available(iOS 27.0, *)
extension CountryEntityQuery: IndexedEntityQuery {
    func reindexEntities(
        for identifiers: [CountryEntity.ID],
        indexDescription: CSSearchableIndexDescription
    ) async throws {
        let identifiers = Set(identifiers.map { $0.uppercased() })
        let entities = await countryEntities(locale: CountrySpotlightIndex.indexingLocale) {
            identifiers.contains($0.code)
        }
        try await CountrySpotlightIndex.index(entities)
    }

    func reindexAllEntities(
        indexDescription: CSSearchableIndexDescription
    ) async throws {
        try await CountrySpotlightIndex.indexAllCountries(force: true)
    }
}
