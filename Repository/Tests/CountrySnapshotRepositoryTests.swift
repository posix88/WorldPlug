import Foundation
@testable import Repository
import Testing

struct CountrySnapshotRepositoryTests {
    @Test
    func loadsCountriesSortedByLocalizedName() throws {
        let countries = try CountrySnapshotRepository.allCountries(locale: Locale(identifier: "en_US"))

        #expect(countries.isEmpty == false)
        #expect(countries.first?.name == "Afghanistan")
    }

    @Test
    func findsCountryByCode() throws {
        let italy = try CountrySnapshotRepository.country(code: "it", locale: Locale(identifier: "en_US"))

        #expect(italy?.code == "IT")
        #expect(italy?.name == "Italy")
        #expect(italy?.plugTypeIDs.isEmpty == false)
    }

    @Test("Finds Maldives with its electrical profile")
    func findsMaldivesByCode() throws {
        let maldives = try #require(
            try CountrySnapshotRepository.country(code: "mv", locale: Locale(identifier: "en_US"))
        )

        #expect(maldives.name == "Maldives")
        #expect(maldives.voltage == "230V")
        #expect(maldives.frequency == "50Hz")
        #expect(maldives.flagUnicode == "🇲🇻")
        #expect(maldives.plugTypeIDs == ["C", "D", "G"])
    }

    @Test(
        "Traveler regions have a standardized flag emoji",
        arguments: [
            ("AX", "🇦🇽"), ("BL", "🇧🇱"), ("BQ", "🇧🇶"), ("CC", "🇨🇨"),
            ("CW", "🇨🇼"), ("CX", "🇨🇽"), ("GG", "🇬🇬"), ("JE", "🇯🇪"),
            ("MH", "🇲🇭"), ("ML", "🇲🇱"), ("MP", "🇲🇵"), ("NF", "🇳🇫"),
            ("NU", "🇳🇺"), ("PF", "🇵🇫"), ("PM", "🇵🇲"), ("PN", "🇵🇳"),
            ("PS", "🇵🇸"), ("SH", "🇸🇭"), ("SJ", "🇸🇯"), ("SS", "🇸🇸"),
            ("SX", "🇸🇽"), ("TK", "🇹🇰"), ("VA", "🇻🇦"), ("VG", "🇻🇬"),
            ("WF", "🇼🇫"), ("YT", "🇾🇹")
        ]
    )
    func travelerRegionsHaveFlagEmoji(code: String, expectedFlag: String) throws {
        let country = try #require(
            try CountrySnapshotRepository.country(code: code, locale: Locale(identifier: "en_US"))
        )

        #expect(country.flagUnicode == expectedFlag)
    }

    @Test("Excludes the restricted British Indian Ocean Territory")
    func doesNotIncludeBritishIndianOceanTerritory() throws {
        let country = try CountrySnapshotRepository.country(code: "IO", locale: Locale(identifier: "en_US"))

        #expect(country == nil)
    }
}
