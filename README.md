# Voltly

Your travel companion for electrical plug types, voltage, and socket standards in 200+
countries — with a per-device packing safety check, camera label scanning, Siri/Spotlight
support, and home-screen widgets. Xcode project name is still `WorldPlug`; bundle id is
`com.posix88.Voltly`.

For architecture, module ownership, and known issues, see **[CLAUDE.md](CLAUDE.md)** — read
that before making non-trivial changes, especially to `TripCheck`'s safety logic
(`DeviceSafetyAssessment`/`VoltageCompatibility`) or the App Group contract shared with the
widget extension.

## Requirements

- **Xcode 27** (currently only shipping as a beta) — the project needs the iOS 27 SDK for
  `FoundationModels`; Xcode 26.x fails to build `FoundationModelDeviceLabelInterpreter.swift`.
- iOS 26.0+ deployment target, Swift 6, strict concurrency.

## Getting started

Install the git hook that runs SwiftFormat before every commit:

```sh
git config core.hooksPath './hooks'
```

Open `WorldPlug.xcodeproj` and run the `WorldPlug` scheme. Swift Testing suites live in
`WorldPlugTests/`, `Repository/Tests/`, and `Analytics/Tests/` — run them from Xcode, or:

```sh
bundle install          # one-time, pins fastlane via the root Gemfile
bundle exec fastlane test
```

## Modules

| Module | Type | Owns |
|---|---|---|
| `WorldPlug/` | App target | SwiftUI app, all features, App Intents, analytics wiring |
| `Repository/` | SwiftPM package | SwiftData models, versioned schema/migrations, bundled country/plug catalog |
| `Analytics/` | SwiftPM package | `AnalyticsTracker` protocol + Firebase Analytics implementation |
| `VoltlyWidgets/` | Widget extension | Home Country, Favorite Country, Next Trip widgets |
| `Tools/Formatter/` | SwiftPM package | Vendored SwiftFormat CLI used by the pre-commit hook |

## Shipping a build

The whole build → sign → upload pipeline is fastlane-driven:

```sh
bundle exec fastlane test     # run the test suite
bundle exec fastlane beta     # bump build number, archive, upload to TestFlight
bundle exec fastlane release  # + push metadata and screenshots to App Store Connect
```

See **[fastlane/README.md](fastlane/README.md)** for one-time setup (App Store Connect API key,
required env vars) and **[AppStore/LAUNCH_PLAN.md](AppStore/LAUNCH_PLAN.md)** for the full launch
checklist — what's one-time-manual in App Store Connect vs. automated here, plus the drafted
EN/IT listing copy. Captioned App Store screenshots are generated via
**[Scripts/screenshots/](Scripts/screenshots/README.md)**, which composites raw simulator
captures with on-brand captions instead of a generic frame.
