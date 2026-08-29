import Foundation
import Repository
import Testing
@testable import WorldPlug

// MARK: - VoltlyDeepLinkTests

//
// App-target unit tests. Add test suites here for any type that lives
// in the WorldPlug target and cannot be moved to the Repository package.
//
// Example:
//   @Suite("PlugDetailViewModel")
//   @MainActor
//   struct PlugDetailViewModelTests { ... }

@Suite("VoltlyDeepLink")
struct VoltlyDeepLinkTests {
    @Test("country URL parses a normalized country code")
    func countryURLParsesCode() throws {
        let url = try #require(URL(string: "voltly://country/it"))

        #expect(VoltlyDeepLink.countryCode(from: url) == "IT")
    }

    @Test("unrelated URL is not treated as a Voltly route")
    func unrelatedURLIsRejected() throws {
        let url = try #require(URL(string: "https://example.com/country/IT"))

        #expect(VoltlyDeepLink.countryCode(from: url) == nil)
        #expect(VoltlyDeepLink.isPremiumURL(url) == false)
    }
}

// MARK: - AppNavigationModelTests

@Suite("AppNavigationModel")
@MainActor
struct AppNavigationModelTests {
    @Test("opening a country routes to its detail")
    func openCountryRoutesToDetail() {
        let navigationModel = AppNavigationModel.shared
        navigationModel.selectedTab = .saved
        navigationModel.deepLinkedCountryCode = nil

        navigationModel.openCountry(code: "it")

        #expect(navigationModel.selectedTab == .countries)
        #expect(navigationModel.deepLinkedCountryCode == "IT")
    }
}

// MARK: - AppCoordinatorTests

@Suite("AppCoordinator", .serialized)
@MainActor
struct AppCoordinatorTests {
    @Test("first launch transitions directly from launch experience to onboarding")
    func firstLaunchTransitionsToOnboarding() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let coordinator = makeCoordinator(standardDefaults: defaults)

        #expect(coordinator.phase == .launchExperience)

        coordinator.launchExperienceCompleted()

        #expect(coordinator.phase == .onboarding)
    }

    @Test("onboarding completion transitions to the main app")
    func onboardingCompletionTransitionsToMainApp() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let coordinator = makeCoordinator(standardDefaults: defaults)
        coordinator.launchExperienceCompleted()

        coordinator.onboardingCompleted()

        #expect(coordinator.phase == .main)
        #expect(defaults.bool(forKey: "hasSeenOnboarding"))
    }

    @Test("returning users transition directly to the main app")
    func returningUsersTransitionToMainApp() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        defaults.set(true, forKey: "hasSeenOnboarding")
        let coordinator = makeCoordinator(standardDefaults: defaults)

        coordinator.launchExperienceCompleted()

        #expect(coordinator.phase == .main)
    }

    private var defaultsSuiteName: String {
        "AppCoordinatorTests"
    }

    private func makeDefaults() throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: defaultsSuiteName))
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        return defaults
    }

    private func makeCoordinator(standardDefaults: UserDefaults) -> AppCoordinator {
        AppCoordinator(
            homeCountryViewModel: PreviewHomeCountryViewModel(),
            premiumEntitlement: PreviewPremiumEntitlement(isPremium: false),
            navigationModel: .shared,
            appGroupDefaults: standardDefaults,
            standardDefaults: standardDefaults
        )
    }
}

// MARK: - ViewAnnotationEntityTests

@Suite("View annotation entities")
@MainActor
struct ViewAnnotationEntityTests {
    @Test("plug entity preserves the catalogue identifier")
    func plugEntityPreservesIdentifier() {
        let plug = Plug(
            id: "G",
            images: [],
            specifications: PlugSpecifications(
                pinDiameter: "",
                pinSpacing: "",
                ratedAmperage: "",
                alsoKnownAs: ""
            )
        )

        let entity = PlugEntity(plug: plug)

        #expect(entity.id == "G")
        #expect(entity.type == "G")
    }

    @Test("trip entity exposes stable contextual data")
    func tripEntityExposesContext() {
        let tripID = UUID()
        let device = PackDevice(
            name: "Laptop",
            symbolName: "laptopcomputer",
            voltage: "100-240 V",
            frequency: "50/60 Hz"
        )
        let trip = TripCheck(
            id: tripID,
            countryCode: "JP",
            name: "Tokyo",
            devices: [device]
        )

        let entity = TripCheckEntity(tripCheck: trip)

        #expect(entity.id == tripID)
        #expect(entity.name == "Tokyo")
        #expect(entity.destinationCode == "JP")
        #expect(entity.deviceCount == 1)
    }

    @Test("device entity preserves electrical input")
    func deviceEntityPreservesElectricalInput() {
        let deviceID = UUID()
        let device = PackDevice(
            id: deviceID,
            name: "Laptop",
            symbolName: "laptopcomputer",
            voltage: "100-240 V",
            frequency: "50/60 Hz"
        )

        let entity = PackDeviceEntity(device: device)

        #expect(entity.id == deviceID)
        #expect(entity.name == "Laptop")
        #expect(entity.voltage == "100-240 V")
        #expect(entity.frequency == "50/60 Hz")
    }

    @Test("legacy device identifiers are stable and distinct")
    func legacyDeviceIdentifiersAreStableAndDistinct() {
        let tripID = UUID()

        let first = PackDevice(legacyDevice: .phone, tripID: tripID, index: 0)
        let repeated = PackDevice(legacyDevice: .phone, tripID: tripID, index: 0)
        let duplicateAtNextIndex = PackDevice(legacyDevice: .phone, tripID: tripID, index: 1)

        #expect(first.id == repeated.id)
        #expect(first.id != duplicateAtNextIndex.id)
    }

    @Test("device query resolves the identifier used by the view annotation")
    func deviceQueryResolvesAnnotatedIdentifier() async throws {
        let device = PackDevice(
            name: "Laptop",
            symbolName: "laptopcomputer",
            voltage: "100-240 V",
            frequency: "50/60 Hz"
        )
        let preferences = TravelPreferences(
            tripChecks: [
                TripCheck(countryCode: "JP", devices: [device])
            ]
        )
        let query = PackDeviceEntityQuery {
            preferences
        }

        let entities = try await query.entities(for: [device.id])

        #expect(entities.map(\.id) == [device.id])
    }
}

// MARK: - CountryEntityTests

@Suite("CountryEntity")
@MainActor
struct CountryEntityTests {
    @Test("entity exposes rich electrical metadata")
    func exposesRichElectricalMetadata() {
        let plug = Plug(
            id: "C",
            images: [],
            specifications: PlugSpecifications(
                pinDiameter: "",
                pinSpacing: "",
                ratedAmperage: "",
                alsoKnownAs: ""
            )
        )
        let entity = CountryEntity(
            country: Country(
                code: "IT",
                voltage: "230V",
                frequency: "50Hz",
                flagUnicode: "🇮🇹",
                plugs: [plug]
            ),
            locale: Locale(identifier: "en_US")
        )

        #expect(entity.voltage == "230V")
        #expect(entity.frequency == "50Hz")
        #expect(entity.plugTypes == ["C"])
        #expect(entity.electricalInformation.contains("230V"))
    }
}
