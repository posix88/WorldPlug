# Socket Buddy — App Store Launch Plan

**Socket Buddy** is the App Store / marketing name — "Voltly" turned out to already be taken. Internally the bundle ID, App Group, URL scheme (`voltly://`), and Swift type names (`VoltlyApp`, `VoltlyWidgets`, `VoltlyDeepLink`, …) all still say "Voltly" — none of that is user-visible or checked against other apps, so it was left alone. See [CLAUDE.md](../CLAUDE.md) for the full internal/external naming split.

Bundle ID `com.posix88.Voltly` · Primary category **Travel** (already set via `INFOPLIST_KEY_LSApplicationCategoryType`) · One IAP: `com.posix88.voltly.premium` ("Socket Buddy Premium", non-consumable, $4.99).

This plan assumes the app itself is code-complete (see the correctness review above/[CLAUDE.md](../CLAUDE.md) for the outstanding bugs — fix at least items 1–3 there before submitting). Everything below is what's left to actually get to "Ready for Sale."

---

## 1. App Store Connect setup checklist

- [ ] Create the app record in App Store Connect (bundle ID `com.posix88.Voltly`), if not already created.
- [ ] Create the in-app purchase `com.posix88.voltly.premium` as **Non-Consumable**, display name "Socket Buddy Premium", price tier matching $4.99 — this must be created and in "Ready to Submit" state *before* you submit the app binary that references it, or the binary validation / review can stall.
- [ ] Fill in the two localizations for the IAP exactly as drafted in [`WorldPlug/Resources/StoreKit/Voltly.storekit`](../WorldPlug/Resources/StoreKit/Voltly.storekit): EN "Scan labels, checks, trips, and widgets.", IT "Scansiona etichette, viaggi e widget."
- [ ] Add **App Privacy** ("nutrition label") answers — see §5 below.
- [ ] Answer the **Age Rating** questionnaire — nothing in the app suggests anything above 4+ (no user-generated content, no unrestricted web access, no gambling; camera use is only for on-device label scanning, not saving or sharing photos).
- [ ] Set primary category **Travel**; consider secondary category **Utilities**.
- [ ] Add support URL and marketing URL (a simple landing page or even a GitHub Pages README works for a v1 — App Store requires a working support URL).
- [ ] Add a privacy policy URL (**required** because you collect analytics data and sync via iCloud — see §5; a one-page policy is enough, several free generators exist, or write ~1 page by hand covering Firebase Analytics + iCloud KVS + no ad tracking).
- [ ] Set up App Store Connect **TestFlight** internal testing build first, sanity-check the paywall against a **Sandbox Apple ID**, and confirm `Transaction.updates` + `AppStore.sync()` behave against the sandbox before submitting for review (StoreKit sandbox behaves differently enough from production that this is worth doing even solo).
- [ ] Localize the App Store *listing itself* for both `en-US` and `it` (App Store Connect lets you pick which locales to support — add both). Note: App Store Connect's locale code for Italian is bare `it`, not `it-IT` — `deliver` rejects `it-IT` as an invalid directory name (confirmed the hard way).

Exact field values, IAP configuration, privacy answers, and submission checks are now documented in
[`APP_STORE_CONNECT_SETUP.md`](APP_STORE_CONNECT_SETUP.md). The publishable policy and product page
live in the separate `posix88.github.io` repository, and their public URLs are included in both
fastlane metadata locales.

## 2. Metadata copy — English (`en-US`)

**App name** (≤30 chars) — already set in `fastlane/metadata/en-US/name.txt`:
- `Socket Buddy: Plugs & Voltage` (29 chars)

**Subtitle** (≤30 chars):
> Plugs, voltage & Apple Watch

**Promotional text** (≤170 chars, editable anytime without a new binary):
> Never get stuck with the wrong plug again. Check 200+ countries, scan device labels, plan trips, and check saved places from your Apple Watch — all offline.

**Keywords** (≤100 chars, comma-separated, no spaces — App Store Connect counts every character):
```
plug,adapter,voltage,socket,travel,converter,outlet,electricity,frequency,charger,watch,trip
```

**Description** — the canonical copy lives in [`fastlane/metadata/en-US/description.txt`](../fastlane/metadata/en-US/description.txt) (≤4000 chars). It used to be duplicated inline here, and drifted: after the Trips restructure this file still advertised "Pack Checks" and a "Next Trip" as two separate features, and claimed saved countries were premium-only when they are now free up to three. Edit the metadata file, not a copy in this doc.

**What's New (first version)**:
> Apple Watch is here. Keep your home country, saved countries, and plug details for 200+ countries on your wrist. Your choices sync privately with Socket Buddy on iPhone.

## 3. Metadata copy — Italian (`it`)

**Nome app** (≤30 caratteri) — già impostato in `fastlane/metadata/it/name.txt`:
- `Socket Buddy: Prese in viaggio` (30 caratteri)

**Sottotitolo** (≤30 caratteri):
> Prese, voltaggio, Apple Watch

**Testo promozionale** (≤170 caratteri):
> Non ritrovarti mai più con la spina sbagliata: compatibilità per oltre 200 paesi, scansione delle etichette, viaggi e paesi salvati su Apple Watch, tutto offline.

**Parole chiave** (≤100 caratteri, separate da virgola, senza spazi):
```
spina,adattatore,voltaggio,presa,viaggio,convertitore,elettricità,frequenza,caricabatterie,watch
```

**Descrizione** (≤4000 caratteri):
See [`fastlane/metadata/it/description.txt`](../fastlane/metadata/it/description.txt) — same rule as the English copy above: edit the metadata file, not this doc.

**Novità (prima versione)**:
> Socket Buddy arriva su Apple Watch. Tieni al polso il paese di origine, i paesi salvati e le informazioni sulle prese di oltre 200 paesi. Le tue scelte si sincronizzano in privato con Socket Buddy su iPhone.

> **Note on the Italian copy**: the native-speaker pass was done on 2026-09-11 (see the dated entry in `CLAUDE.md`) — description, subtitle, promotional text and release notes were rewritten, not just spot-checked. The app *name* (`Socket Buddy: Prese in viaggio`) was reviewed and deliberately kept. It's at the 30-character ceiling, so any future edit has to trade a word for a word.

## 3b. Copyright (not localized)

`fastlane/metadata/copyright.txt` → `2026 Antonino Musolino`. App Store Connect renders this as
"© 2026 Antonino Musolino" on the product page, so the file must **not** contain the © symbol itself.
It's a single app-level value, not per-locale, which is why it lives in `fastlane/metadata/` rather
than in the `en-US/` and `it/` folders.

## 4. Screenshots

`AppStore/Screenshots/{en-US,it}/` — iPhone, iPad, and Apple Watch screenshots all ready. Apple changes required screenshot sizes periodically — treat the table below as a starting point and let App Store Connect's upload screen be the source of truth at submission time:

| Device | Size (px) | Required? | Source |
|---|---|---|---|
| iPhone 6.9" (17 Pro Max / 16 Pro Max class) | 1320 × 2868 (or 2868 × 1320 landscape) | **Yes** — this is the baseline set Apple requires | Captured from simulator in `raw/` |
| iPhone 6.5"/6.7" | 1290 × 2796 | Optional if 6.9" set supplied and you don't need older-device-specific shots | — |
| iPad 13" (12.9"/13" class) | 2048 × 2732 (portrait) | **Yes**, since `TARGETED_DEVICE_FAMILY = "1,2"` (universal) — Apple requires iPad screenshots for any app that supports iPad | **Upscaled automatically from iPhone raws** — since the UI is universal (same layout on both devices), iPad screenshots are generated by the rendering pipeline from the iPhone raw captures |
| Apple Watch Series 12 (46mm) | 416 × 496 (portrait) | **Yes**, required for the standalone Apple Watch app | Captured and framed by `bundle exec fastlane watch_screenshots` |

You need **3–10 screenshots per device size per locale** (5 is a good target). Suggested shot list, matched to what actually exists in the app today:

1. **Countries tab** — the list with a few flags visible and a compatibility badge showing, ideally with the home-country banner set (shows the "instant compatibility" value prop immediately).
2. **Country Detail** — a popular destination (e.g. Japan or UK — visually distinct plug shapes) showing plug diagrams + voltage/frequency + the map.
3. **Trip detail** — a trip's packed-devices list with a mix of ✅ Compatible / ⚠️ Adapter needed verdicts, to sell the "so you don't fry your charger" hook.
4. **Device label scanner** — the camera view mid-scan with recognized text highlighted (this is the most differentiated, "wow" feature — put it early, not last).
5. **Trips list + Saved countries** — the Upcoming/Past trip list with the NEXT badge, and the starred-countries tab; shows the premium value without being the paywall itself.
6. **Widgets on the Home Screen** — done: the Next Trip large widget with the two small ones (Favorite country, My country) above it, on an otherwise empty Home Screen page. Captured by `bundle exec fastlane capture_widget_screenshots`, which needs a one-off `fastlane prepare_widget_device` first (XCUITest can't drive SpringBoard, so placing the widgets that first time is the only manual step).

### Captioning: use the on-brand renderer, not `frameit`

`Scripts/screenshots/` has a working, on-brand captioning pipeline — an HTML/CSS template using
Socket Buddy's actual colors (the cosmic mesh gradient from `AppMeshBackground.swift`, the volt-tint
gold accent) rendered to a pixel-perfect PNG via headless Chrome, instead of `fastlane frameit`'s
flat-color/system-font look. Two real examples are already rendered in
`Scripts/screenshots/out/en-US/` from the actual running app (Countries list, and a trip-detail
"do not use without a converter" verdict) — open them to see the actual output before doing your
own. Full usage in `Scripts/screenshots/README.md`, including how to wire it up behind `fastlane
snapshot` once a UI Testing target exists for full multi-device/locale automation.

**iPad screenshots are generated automatically**: The pipeline now automatically upscales iPhone raw
captures to iPad dimensions (2048 × 2732) during rendering, since the UI is universal. No separate
iPad capture is needed — one iPhone raw becomes both an iPhone screenshot and an iPad one, both with
captions.

**Screenshot workflow** (use granular lanes when you need only one set):
```bash
# 1. Capture raw iPhone screenshots (from XCUITest)
bundle exec fastlane capture_raw_screenshots

# 2. Capture widget screenshots (one-time after fastlane prepare_widget_device)
bundle exec fastlane capture_widget_screenshots

# 3. Render all screenshots with captions (iPhone 1320×2868 + iPad 2048×2732, both locales)
bundle exec fastlane render_screenshots
```

Or refresh every automatable screenshot set, including Watch, in one command:
```bash
bundle exec fastlane screenshots
```

To refresh only the Watch set:
```bash
bundle exec fastlane watch_screenshots
```

Or skip step 2 if you don't need widget screenshots:
```bash
bundle exec fastlane capture_raw_screenshots
bundle exec fastlane render_screenshots
```

The final PNGs are ready in `AppStore/Screenshots/` organized by locale with device-specific suffixes:
```
AppStore/Screenshots/
├── en-US/
│   ├── 01_countries.png          (5 iPhone screenshots, 1320×2868)
│   ├── 01_countries_IPAD.png     (5 iPad screenshots, 2048×2732, upscaled)
│   ├── 02_tripcheck.png
│   ├── 02_tripcheck_IPAD.png
│   ├── 03_countrydetail.png
│   ├── 03_countrydetail_IPAD.png
│   ├── 05_saved.png
│   ├── 05_saved_IPAD.png
│   ├── 06_widgets.png
│   ├── 06_widgets_IPAD.png
│   ├── watch_01_home.png        (Apple Watch Series 12, 416×496)
│   ├── watch_02_saved.png
│   ├── watch_03_home_country.png
│   ├── watch_04_countries.png
│   └── watch_05_italy.png
└── it/
    ├── 01_countries.png
    ├── 01_countries_IPAD.png
    ├── 02_tripcheck.png
    ├── 02_tripcheck_IPAD.png
    ├── 03_countrydetail.png
    ├── 03_countrydetail_IPAD.png
    ├── 05_saved.png
    ├── 05_saved_IPAD.png
    ├── 06_widgets.png
    ├── 06_widgets_IPAD.png
    ├── watch_01_home.png        (Apple Watch Series 12, 416×496)
    ├── watch_02_saved.png
    ├── watch_03_home_country.png
    ├── watch_04_countries.png
    └── watch_05_italy.png
```

**Note**: Fastlane/deliver requires device-specific screenshots to have `_IPAD` suffix in the
filename for it to recognize and upload them to the iPad screenshot slot in App Store Connect.
The `_IPAD` suffix is added automatically during rendering.

Captions are defined in `Scripts/screenshots/captions.json` and are shared between iPhone and iPad
renders. To modify captions, edit that file and re-run `fastlane render_screenshots`.

## 5. App Privacy ("nutrition label")

Based on what's actually in the code (`Analytics` package → Firebase Analytics only; no Crashlytics, no ads SDK, no third-party trackers found in `Package.swift`/target dependencies):

| Data type | Collected? | Linked to identity? | Used for tracking? |
|---|---|---|---|
| Product interaction / usage data (your `AnalyticsEvent` cases — onboarding, saves, etc.) | Yes (Firebase Analytics) | No (unless you've enabled `setUserID`/`setUserProperty` with identifying data — check `AnalyticsTracker.swift`, it doesn't appear to) | No |
| Identifiers (Firebase App Instance ID) | Yes, automatically by the SDK | No | No |
| Purchase history | Yes (Firebase automatically measures in-app purchase events) | No | No |
| Coarse location | Yes (Firebase may derive approximate location from network information; the app never requests device location) | No | No |
| Other diagnostic data | Yes (Firebase Installations declares technical diagnostic data for analytics) | No | No |
| User content (saved countries, next trip, pack devices) | No developer collection — stored only on-device and in the user's own iCloud account (`NSUbiquitousKeyValueStore`) | — | — |
| Camera | Used locally only (label scanning); a transient image may be processed in memory but is never saved or uploaded | — | — |

Answer "Data Used to Track You": **No** (there's no IDFA/ATT usage found anywhere in the codebase — confirm no `AppTrackingTransparency` import exists, which matches what was found).

Action items:
- [x] Double-check Firebase Analytics initialization for `setUserID`, user properties, ATT, or advertising identifiers — none are present.
- [x] Write the privacy policy covering Firebase Analytics, iCloud sync, StoreKit, and on-device camera processing.

## 6. Suggested pre-submission order of operations

1. ~~Fix the top items in [CLAUDE.md](../CLAUDE.md)'s "Known issues"~~ — done; see that file's log.
2. Create the IAP in App Store Connect and verify a Sandbox purchase + restore end-to-end on a real device.
3. Write and host the privacy policy; fill in App Privacy answers.
4. Capture and caption screenshots (§4) — pipeline + two real examples already in `Scripts/screenshots/`.
5. Fill in metadata (§2/§3) — already drafted into `fastlane/metadata/{en-US,it}/`, ready for `fastlane release`/`fastlane metadata`/`fastlane upload_metadata` to push (see below); do a native-speaker pass on the Italian copy first.
6. Generate an App Store Connect API key and set up `fastlane/.env` — see `fastlane/README.md`.
7. `bundle exec fastlane beta` — runs the test suite, bumps the build number, archives, and uploads to TestFlight. Install it on a real device yourself first; StoreKit sandbox, widgets, and the camera permission prompt all behave subtly differently on-device than in the simulator.
8. `bundle exec fastlane release` once TestFlight checks out — uploads the build plus metadata and screenshots to App Store Connect, but leaves `submit_for_review: false` on purpose. Review everything in App Store Connect's UI, then either flip that flag in `fastlane/Fastfile` or hit submit manually — a deliberate last step, not a side effect of running a lane.
