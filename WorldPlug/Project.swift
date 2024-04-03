import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "WorldPlug",
    settings: .projectSettings,
    targets: [
        .target(
            name: "WorldPlug",
            destinations: .iOS,
            product: .app,
            bundleId: "io.posix88.worldplug",
            infoPlist: "WorldPlug-Info.plist",
            sources: "Sources/**",
            resources: ["Resources/**/*"],
            dependencies: [
                .project(target: "Network_iOS", path: .relativeToRoot("Network")),
                .external(name: "ComposableArchitecture")
            ],
            settings: .targetSettings
        ),
        .target(
            name: "WorldPlugTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.posix88.worldplug",
            infoPlist: .default,
            sources: "Tests/**",
            dependencies: [
                .target(name: "WorldPlug"),
                .external(name: "Nimble"),
            ],
            settings: .targetSettings
        )
    ],
    schemes: Scheme.allSchemes(for: ["WorldPlug"], executable: "WorldPlug")
)
