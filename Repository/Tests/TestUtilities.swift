import Foundation
import SwiftData
import Testing

@testable import Repository

// MARK: - Container

/// Builds an isolated in-memory ModelContainer for each test suite instance.
@MainActor
func makeContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Country.self, Plug.self, configurations: config)
}

// MARK: - Factory helpers

func makeSpecs(
    pinDiameter: String = "1.5mm",
    pinSpacing: String = "12.7mm",
    ratedAmperage: String = "10A",
    alsoKnownAs: String = "NEMA 1-15"
) -> PlugSpecifications {
    PlugSpecifications(
        pinDiameter: pinDiameter,
        pinSpacing: pinSpacing,
        ratedAmperage: ratedAmperage,
        alsoKnownAs: alsoKnownAs
    )
}

@MainActor
func makePlug(
    id: String,
    context: ModelContext
) -> Plug {
    let plug = Plug(
        id: id,
        images: [],
        specifications: makeSpecs()
    )
    context.insert(plug)
    return plug
}

@MainActor
func makeCountry(
    code: String,
    voltage: String = "230V",
    frequency: String = "50Hz",
    context: ModelContext
) -> Country {
    let country = Country(code: code, voltage: voltage, frequency: frequency, flagUnicode: "🏳️")
    context.insert(country)
    return country
}
