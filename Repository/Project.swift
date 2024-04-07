import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Repository",
    settings: .projectSettings,
    targets: [
        .target(
            name: "Repository_iOS",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.posix88.worldplug.repository",
            sources: "Sources/*",
            resources: ["Resources/**/*"],
            dependencies: [],
            settings: .targetSettings
        ),
        .target(
            name: "RepositoryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.posix88.worldplug.repository",
            infoPlist: .default,
            sources: "Tests/*",
            dependencies: [
                .target(name: "Repository_iOS"),
                .external(name: "Nimble"),
            ],
            settings: .targetSettings
        )
    ],
    schemes: Scheme.allSchemes(for: ["RepositoryFramework"])
)

