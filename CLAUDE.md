# Socket Buddy — Codebase Guide for AI Agents

Read this before touching the code. It describes what actually exists today, not the aspirational state. Where this file and `.github/copilot-instructions.md` / `.github/instructions/*.md` disagree, **this file wins** — the `.github` docs describe an earlier project layout (pre-reorg, iOS 17) and are stale in places (see "Known doc drift" below). They're still useful for the *conventions* (naming, MVVM shape, testing style), just not for the current folder layout or deployment target.

## What this app is

**Socket Buddy** (Xcode project still named `WorldPlug`, bundle id `com.posix88.Voltly`) is a personal iOS app that tells travelers everything about electrical plugs, sockets, voltage and frequency for 200+ countries, checks whether their devices are safe to use abroad, and lets them save countries/trips behind a one-time $4.99 IAP ("Socket Buddy Premium"). It ships a WidgetKit extension, Siri/Spotlight App Intents, iCloud-synced preferences, and on-device AI (Vision + Apple FoundationModels) for reading device labels via the camera.

**Naming**: the App Store / marketing name is "Socket Buddy" — "Voltly" (the original working name) turned out to already be taken. Every internal identifier still says "Voltly" on purpose (Apple only checks the App Store listing name for uniqueness, not any of these): the bundle ID (`com.posix88.Voltly`), the App Group (`group.com.posix88.Voltly`), the URL scheme (`voltly://`), the Xcode project name (`WorldPlug`), the Firebase project (`voltly-1527f`), and every `Voltly*`-prefixed Swift type (`VoltlyApp`, `VoltlyWidgets`, `VoltlyDeepLink`, `VoltlyAppShortcuts`, …). Only user-visible text was changed: `CFBundleDisplayName`, the onboarding/paywall/share-sheet copy, the camera permission string, the widget empty-state text, and the App Store metadata in `fastlane/metadata/`. Don't "fix" the internal naming without a good reason — it's intentionally left alone, not an oversight.

- Target: iOS 27.0+ (`IPHONEOS_DEPLOYMENT_TARGET = 27.0`), universal (iPhone + iPad), Swift 6.0, **strict concurrency = complete**.
- No `SWIFT_DEFAULT_ACTOR_ISOLATION` override — every `@MainActor` is explicit, by convention. Follow that convention; don't rely on default-MainActor-isolation behavior.
- State: `@Observable` everywhere (never `ObservableObject`/`@Published`).
- Persistence: SwiftData, isolated inside the `Repository` Swift package.
- Testing: Swift Testing (`@Test`/`#expect`), never XCTest.
- Formatting: SwiftFormat via `.swiftformat` at repo root; install the pre-commit hook with `git config core.hooksPath './hooks'` (see [README.md](README.md)).

## Module map

| Module | Type | Owns |
|---|---|---|
| `WorldPlug/` | App target | SwiftUI app, all features, App Intents, analytics wiring |
| `Repository/` | SwiftPM package | SwiftData `@Model`s (`Country`, `Plug`), versioned schema/migrations, JSON-seeded catalog data, `CountrySnapshot` (Sendable read model for widgets), `AppGroup` (shared UserDefaults keys/suite) |
| `Analytics/` | SwiftPM package | `AnalyticsTracker` protocol + Firebase Analytics implementation |
| `VoltlyWidgets/` | Widget extension | Home Country, Favorite Country, Next Trip widgets (all families) |
| `Tools/Formatter/` | SwiftPM package | Vendored SwiftFormat CLI used by the pre-commit hook |
| `WorldPlugTests/`, `Repository/Tests/`, `Analytics/Tests/` | Test targets | Swift Testing suites |

**Rule inherited from the old docs and still true**: `@Model` types live only in `Repository`. The app and widget targets never define SwiftData models directly — they read through `Repository.sharedModelContainer` (app) or `CountrySnapshotRepository`/App Group `UserDefaults` (widgets, since widgets run in a separate process and SwiftData model objects aren't `Sendable` across it).

## App target layout (`WorldPlug/Sources/`)

```
App/                    VoltlyApp (@main), AppDelegate, AppCoordinator, AppNavigationModel,
                         VoltlyDeepLink, RootTabView (3-tab: Countries / Trip Check / Saved),
                         LaunchExperienceView (splash)
App Intents/            OpenCountryIntent, OpenHomeCountryIntent, CountryEntity, CountrySpotlightIndex
Models/
  Home Country/         HomeCountryViewModel + HomeCountryStoring (UserDefaults, App-Group-aware)
  Travel Preferences/   TravelPreferences (Codable value type: saved countries, next trip, pack devices)
                         + ICloudTravelPreferencesStore (NSUbiquitousKeyValueStore-backed)
Features/
  Countries/            Tab 1 — browsable/searchable country list, compatibility badges
  CountryDetail/        Country screen — plugs, map (CountryMapGeocoder/MapKit), compatibility
  PlugDetail/           Single plug-type screen (specs, images, share)
  TripCheck/             Tab 2 — "Pack Check": add devices (presets or camera-scanned label via
                         VisionKit DataScannerViewController + FoundationModels), get a per-device
                         safety verdict against the destination's voltage/frequency/plug type
  SavedCountries/        Tab 3 — saved countries + "Next Trip" planner (both premium-gated)
  Premium/               StoreKit 2 paywall (StoreKitPremiumEntitlement, PremiumPaywallViewModel)
  Onboarding/            First-launch flow: welcome → pick home country → done
UI Components/          Design system: Card, Spacing, SFSymbols, DesignTokens, LocalizationKeys, …
Analytics/              AppReviewPrompt (one-shot review prompt), AnalyticsEnvironment (@Entry)
```

There is also an **empty, dead `WorldPlug/Sources/Screens/` directory tree** (`Countries List/`, `Country Detail/`, `Onboarding/`, `Plug detail/`, `Premium/`, `Saved Countries/`, `Trip Check/`) left over from the `reorganiza project` commit. It holds no files and isn't tracked by git — safe to `rm -rf` locally, just noting it so it doesn't look like a second, half-migrated feature location.

## Core architecture facts an agent needs before editing

- **Navigation**: single `AppNavigationModel.shared` singleton (`@Observable @MainActor`) drives tab selection + deep-linked country code. `AppCoordinator` (also `@MainActor`, owned by `VoltlyApp`) is the app-level state machine: launch splash → onboarding (if first run) → premium paywall presentation → deep link routing. `VoltlyDeepLink` parses `voltly://country/<code>` and `voltly://premium` URLs; widget deep links must match this exactly or tapping the widget silently no-ops.
- **Premium gating**: single source of truth is `StoreKitPremiumEntitlement.isPremium` (`@Observable @MainActor`, StoreKit 2, one non-consumable product `com.posix88.voltly.premium`). It's injected via `@Environment(\.premiumEntitlement)`. `AppCoordinator.syncPremiumWidgetAccess()` mirrors `isPremium` into the App Group `UserDefaults` key `AppGroup.premiumAccessKey` and calls `WidgetCenter.shared.reloadAllTimelines()` — **this is the only bridge between the main app's entitlement and what widgets can show**; if you rename/move that key on one side without the other, widget premium-gating silently breaks.
- **App Group contract** (`Repository/Sources/AppGroup.swift`, suite `group.com.posix88.Voltly`): home country code, favorite country code, next-trip country/departure/return dates, premium flag. Widgets read these directly via `UserDefaults(suiteName:)` and resolve country data through `CountrySnapshotRepository` (a lightweight, `Sendable` read path — not the full SwiftData stack). If you add a new cross-process value, add the key here, write it from the app, and read it identically from every widget provider that needs it.
- **SwiftData schema**: `Repository/Sources/Schema.swift` — `MigrationPlan` currently only lists `SchemaV4 → SchemaV5`. There is commented-out evidence of a pre-existing `V2 → V3` migration, meaning older schema versions existed. `Repository.sharedModelContainer` now degrades gracefully instead of crashing forever on an unopenable store: on any container error (bad migration path, corrupted file) it deletes the default store and retries once before `fatalError`-ing — safe because `Country`/`Plug` are a reseedable catalog, not user data. Still add a real `MigrationStage` when you bump the schema; the fallback is a safety net, not a substitute.
- **iCloud sync**: `ICloudTravelPreferencesStore` wraps `NSUbiquitousKeyValueStore` and observes `didChangeExternallyNotification` (in addition to reloading on `AppCoordinator.sceneBecameActive()`), so changes made on another device (or by the widget extension) show up live, not just on foreground.
- **TripCheck safety logic**: `DeviceSafetyAssessment` + `VoltageCompatibility`/`FrequencyCompatibility` (`Models/Home Country/HomeCountryViewModelType.swift`) decide whether a packed device is `.ready` / `.adapterNeeded` / `.checkLabel` / unsafe for a destination. This is the one piece of business logic with real-world physical-safety consequences (wrong verdict ⇒ user could plug an incompatible device into a wall socket). Read the "Known issues" section before changing tolerances or the label-parsing regexes.
- **Analytics**: `AnalyticsTracker` protocol (`Analytics` package) with a Firebase-backed implementation and `NoopAnalyticsTracker` for previews/tests, injected via `@Environment(\.analyticsTracker)`. `AppDelegate` calls `FirebaseAnalyticsTracker.configure()` in `didFinishLaunchingWithOptions`.
- **Camera usage**: `DeviceLabelScannerView` uses `VisionKit.DataScannerViewController` (not raw `AVCaptureSession`). `NSCameraUsageDescription` **is** correctly set in `en.lproj`/`it.lproj` `InfoPlist.strings` (EN: "Socket Buddy uses the camera to read the voltage and frequency printed on your device label.").

## Localization

- String catalogs live in `WorldPlug/Resources/Copies/`: `Localizable.xcstrings` (220 keys, source language English), `Accessibility.xcstrings`, `AppShortcuts.xcstrings`.
- Two shipping languages: **English** and **Italian**, both essentially fully localized (only interpolation-format placeholder keys like `"%@"` and the brand name `"Socket Buddy"` are identical in both locales, which is correct — a brand name doesn't get translated).
- Access strings through the `LocalizationKeys` enum (`UI Components/Localizable.swift`), not raw string literals — `String(localized: LocalizationKeys.xxx)`.
- `InfoPlist.strings` per-locale (camera usage description, etc.) live in `WorldPlug/Resources/{en,it}.lproj/`.
- `VoltlyWidgets/Sources/WidgetLocalization.swift` handles widget-extension-side localization separately (it can't share the app target's string catalog directly).

## Known issues (from the 2026-08 correctness/concurrency pass)

All findings from the original review have been fixed as of 2026-08-19, across three passes (5 launch-blocking, 6 "worth a look", then the remaining open items). Full build + full test suite (app target on Xcode 27 beta 4 / iOS 27 SDK, arm64 simulator, and the `Repository` SwiftPM package via `swift test`) pass cleanly and repeatably — verified with three consecutive full runs, no flakes. The generic/x86_64 simulator destination still fails to build regardless of any of this — `FoundationModels` isn't available on that slice, a pre-existing environment limitation, not a regression.

**Launch-blocking (fixed):**
1. Onboarding covering the launch splash for first-time users (`AppCoordinator.isOnboardingPresented` now only flips true from `launchExperienceCompleted()`).
2. Missing `NSUbiquitousKeyValueStore.didChangeExternallyNotification` observer in `ICloudTravelPreferencesStore` (now observes live, with a `preferences != oldValue` guard to avoid write-echo).
3. TripCheck safety logic failing open on unparseable voltage/frequency, flat ±20V tolerance, and a label-parsing regex that missed `"AC100-240V"`-style labels (`VoltageCompatibility`/`FrequencyCompatibility`/`DeviceLabelParser`).
4. `Repository.cleanDataBase()` never calling `save()`.
5. Next Trip widget routing already-premium users to the paywall when they simply had no active trip.

**Worth a look (fixed):**
6. Device label scanner double-tap race (`DeviceLabelScannerView` now gates re-entrancy, marks `.analyzing` before the camera capture, and cancels stale tasks).
7. `scannedValues`' `Equatable`-gated `onChange` silently missing a second identical device scan (`PackDeviceEditorView` now resets it to `nil` after consuming it).
8. `CountryMapGeocoder` having no fallback for an inexact MapKit match and no negative-result caching (`bestMapItem` now falls back to the first result; failed lookups are cached in `codesWithoutAFocus` for the session).
9. SwiftData migration plan only covering V4→V5 with a hard `fatalError` on any container error (`Repository.sharedModelContainer` now discards an unopenable store and retries once, since the catalog is fully reseedable).
10. `WidgetPlugs.swift` hardcoding an unlocalized `"Type \(plugType)"` (now uses `WidgetStrings.string("widget.plug.type", plugType)`).
11. StoreKit `.pending` purchases giving no user feedback (`PremiumPaywallViewModel.isPurchasePending` + a dedicated "Purchase pending" alert, new EN/IT keys).

**Remaining findings from the full review (fixed):**
12. Redundant full Spotlight reindex on every cold launch — `CountrySpotlightIndex.indexAllCountries()` now only reindexes when `CFBundleShortVersionString` has changed since the last successful index (stamped in `UserDefaults`).
13. `OpenHomeCountryIntent` reading only the App Group suite instead of reusing `UserDefaultsHomeCountryStore`'s App-Group-with-standard-defaults fallback — now reuses it, matching the rest of the app.
14. `preloadData()`/container-recovery failures only ever `print`ed — `Repository` now has an `os.Logger` (`com.posix88.Voltly.Repository`) so failures show up in Console/Xcode's log views instead of being easy to miss.
15. Launch splash dismissing on a fixed timer independent of `premiumEntitlement.refreshEntitlements()` completing — `AppCoordinator.hasRefreshedEntitlements` + `LaunchExperienceView(isReady:)` now gate dismissal on both the minimum splash duration *and* entitlement refresh finishing (with a ~3s total safety-net timeout so a slow/hung refresh can never block the splash indefinitely).
16. `CountryMapGeocoder` geocoding taking a fixed 2s delay before animating regardless of network speed, and no "couldn't locate" state distinct from "still locating" — added `CountryMapLoadState` (`.locating`/`.located`/`.unavailable`) to `CountryDetailViewModel`, surfaced as a small pill (`country.detail.map.unavailable`, new EN/IT keys) over the map when geocoding genuinely fails. The 2s delay itself was left as-is — it's a deliberate "let the globe settle, then fly in" animation beat, not a bug.
17. `CountriesListViewModel.fetchData()` silently leaving the catalog empty on a fetch error in release builds (`assertionFailure` is a no-op there) — now also tracks a new `.catalogFetchFailed` analytics event with the error description.
18. `NextTripEditorViewModel`'s "return date can't precede departure" invariant only being enforced reactively via `departureDateChanged()`, not at construction — now also clamped in `init`.
19. Camera/photo-capture failures being silently swallowed with no telemetry (`try? scanner.startScanning()`, the FoundationModel-interpreter-throws-so-fall-back-to-Vision path) — both now tracked via new `.deviceLabelScanStartFailed`/`.deviceLabelSmartAnalysisFailed` analytics events; the graceful-degradation *behavior* is unchanged, only visibility was added.

**Two test issues found during verification, also fixed (not part of the original review, found while confirming the above didn't regress anything):**
- `CountriesListViewModelTests.refreshCompatibilitySummaries()` was failing deterministically on unmodified `main` too: its `japan`/`usa` fixtures had no plugs, so `CountryCompatibilityCalculator.summary(for:)` (which only derives a verdict from `country.sortedPlugs`) had nothing to iterate over and always returned `.compatible`. Fixed by giving the fixture countries a plug each, matching real catalog data (every real country has at least one).
- A `HomeCountryViewModelTests` test was failing intermittently (a different one each run), consistent with SwiftData in-memory `ModelConfiguration` containers colliding under Swift Testing's default parallel execution. Fixed by marking both `CountriesListViewModelTests` and `HomeCountryViewModelTests` `@Suite(..., .serialized)`.

**Nothing left open from this review.** If you're reading this after making more changes, add a new dated section here rather than editing history above — keep this list a log, not just a snapshot.

## Known doc drift (`.github/` is not authoritative)

`.github/copilot-instructions.md` and `.github/instructions/*.md` (gitignored, so they're local-only reference material, not shipped with the repo) describe:
- `WorldPlug/Sources/Countries List/` and `Plug detail/` as top-level folders — the real layout is `Features/Countries/` and `Features/PlugDetail/` (see module map above).
- "iOS 17.0 minimum deployment" — the actual project target is **iOS 27.0**.
- `SchemaV4` as current — the actual current schema is **SchemaV5**.
They're still accurate on *conventions* (MVVM shape, `XxxViewModelType` protocols, SwiftData rules, testing framework, localization approach) — trust them for "how do we do X here", not for "where does X live" or "what version are we on".

## Before you ship

- No fastlane/CI screenshot or App Store automation exists yet (`Scripts/` only has `run_swiftformat.sh`). See the App Store launch plan the user was given alongside this file for what's still needed (screenshots, IT/EN metadata, privacy nutrition label, etc.).
- `AppStore/Screenshots/{en-US,it}/` directories exist — two shots done, more still need to be captured (see AppStore/LAUNCH_PLAN.md §4). Locale folder is `it`, not `it-IT` — App Store Connect's `deliver` rejects `it-IT` as an invalid directory name.
