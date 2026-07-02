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
}
