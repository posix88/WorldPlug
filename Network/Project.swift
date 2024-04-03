import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Network",
    settings: .projectSettings,
    targets: [
        .target(
            name: "Network_iOS",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.posix88.worldplug.network",
            sources: "Sources/*",
            dependencies: [],
            settings: .targetSettings
        ),
        .target(
            name: "NetworkTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.posix88.worldplug.network",
            infoPlist: .default,
            sources: "Tests/*",
            dependencies: [
                .target(name: "Network_iOS"),
                .external(name: "Nimble"),
            ],
            settings: .targetSettings
        )
    ],
    schemes: Scheme.allSchemes(for: ["NetworkFramework"])
)
