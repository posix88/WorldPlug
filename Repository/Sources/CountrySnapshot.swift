import Foundation

// MARK: - CountrySnapshot

public struct CountrySnapshot: Equatable, Sendable {
    public let code: String
    public let name: String
    public let voltage: String
    public let frequency: String
    public let flagUnicode: String
    public let plugTypeIDs: [String]

    public init(
        code: String,
        name: String,
        voltage: String,
        frequency: String,
        flagUnicode: String,
        plugTypeIDs: [String]
    ) {
        self.code = code
        self.name = name
        self.voltage = voltage
        self.frequency = frequency
        self.flagUnicode = flagUnicode
        self.plugTypeIDs = plugTypeIDs
    }
}

// MARK: - CountrySnapshotRepository

public enum CountrySnapshotRepository {
    public static func allCountries(locale: Locale = .current) throws -> [CountrySnapshot] {
        let countries = try loadCountries()
        return countries
            .map { $0.snapshot(locale: locale) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public static func country(code: String, locale: Locale = .current) throws -> CountrySnapshot? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedCode.isEmpty else {
            return nil
        }

        return try loadCountries()
            .first(where: { $0.code == normalizedCode })?
            .snapshot(locale: locale)
    }

    private static func loadCountries() throws -> [CountrySnapshotDecodable] {
        guard let url = Bundle.module.url(forResource: "countries", withExtension: "json") else {
            throw CountrySnapshotRepositoryError.missingResource
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CountrySnapshotDecodable].self, from: data)
    }
}

// MARK: - CountrySnapshotRepositoryError

public enum CountrySnapshotRepositoryError: Error {
    case missingResource
}

// MARK: - CountrySnapshotDecodable

private struct CountrySnapshotDecodable: Decodable {
    let code: String
    let voltage: String
    let frequency: String
    let flagUnicode: String
    let plugTypes: [String]

    enum CodingKeys: String, CodingKey {
        case code = "country_code"
        case voltage
        case frequency
        case flagUnicode = "flag_emoji"
        case plugTypes = "plug_types"
    }

    func snapshot(locale: Locale) -> CountrySnapshot {
        CountrySnapshot(
            code: code,
            name: locale.localizedString(forRegionCode: code) ?? code,
            voltage: voltage,
            frequency: frequency,
            flagUnicode: flagUnicode,
            plugTypeIDs: plugTypes
        )
    }
}
