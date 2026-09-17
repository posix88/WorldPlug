# App Store Connect Setup

Use this document for Socket Buddy's first submission. Portal actions cannot be committed to the
repository, so check each item in App Store Connect before uploading the review build.

## App record

| Field | Value |
|---|---|
| Name | Socket Buddy |
| Bundle ID | `com.posix88.Voltly` |
| SKU | `socket-buddy-ios` |
| Primary category | Travel |
| Secondary category | Utilities |
| Copyright | `2026 Antonino Musolino` (canonical copy in `fastlane/metadata/copyright.txt`; not localized) |
| Support URL | <https://posix88.github.io/socketbuddy/privacy.html> |
| Marketing URL | <https://posix88.github.io/socketbuddy> |
| Privacy policy URL | <https://posix88.github.io/socketbuddy/privacy.html> |
| Age rating | Complete questionnaire for 4+ |

Add listing localizations `en-US` and `it`. Metadata files under `fastlane/metadata/` contain the
approved copy and URLs.

## Apple Watch

The submitted Watch app runs independently of its companion iPhone app. After the build finishes
processing, open **Previews and Screenshots → Apple Watch** for each locale and upload the five
416 × 496 screenshots from `AppStore/Screenshots/{en-US,it}/watch_*.png`. Confirm App Store Connect
shows the Watch icon generated from the shared `Voltly.icon` source. The localized descriptions
already explain the Apple Watch functionality.

## In-app purchase

Create this product before submitting the app version:

| Field | Value |
|---|---|
| Reference name | Socket Buddy Premium |
| Product ID | `com.posix88.voltly.premium` |
| Type | Non-Consumable |
| Price | USD 4.99 equivalent |
| Family Sharing | Off |

Localizations:

| Locale | Display name | Description |
|---|---|---|
| English (U.S.) | Socket Buddy Premium | Scan labels, checks, trips, and widgets. |
| Italian | Socket Buddy Premium | Scansiona etichette, viaggi e widget. |

Attach the IAP to the first app version submitted for review. Add a review screenshot showing the
paywall and use `AppStore/REVIEW_NOTES.md` for reviewer instructions.

## App Privacy answers

**Data Used to Track You:** No.

Declare these data types as collected, not linked to identity, not used for tracking, and used for
Analytics:

| App Privacy category | Data type | Collected | Linked | Tracking | Purpose |
|---|---|---:|---:|---:|---|
| Location | Coarse Location | Yes | No | No | Analytics |
| Identifiers | Device ID | Yes | No | No | Analytics |
| Usage Data | Product Interaction | Yes | No | No | Analytics |
| Purchases | Purchase History | Yes | No | No | Analytics |
| Diagnostics | Other Diagnostic Data | Yes | No | No | Analytics |

Do not declare precise location, photos/videos, user content, contact information, or advertising
data. Country map searches use a country name, not device location. A transient camera image may
be processed in memory on-device, but it and the recognized label text are never saved or uploaded.
Saved travel data uses the user's private iCloud key-value store and is not received by a developer
server.

These answers match `WorldPlug/Resources/PrivacyInfo.xcprivacy` and current Firebase Analytics
usage. Re-audit if analytics SDKs, custom user identifiers, advertising, crash reporting, or a
backend are added.

## Submission checks

- [ ] Agreements, tax, and banking are active.
- [ ] App record uses both `en-US` and `it`.
- [ ] Privacy, support, and marketing URLs open without authentication.
- [ ] IAP status is Ready to Submit and attached to app version.
- [ ] App Privacy answers match table above.
- [ ] Age Rating questionnaire resolves to 4+.
- [ ] Export compliance questions completed; app does not implement custom encryption.
- [ ] TestFlight build tested with Sandbox purchase, pending flow where possible, and Restore.
- [ ] Review screenshot for IAP uploaded.
- [ ] `AppStore/REVIEW_NOTES.md` pasted into App Review Information.
- [ ] Final screenshots uploaded for iPhone, iPad, and Apple Watch in both locales.
- [ ] Apple Watch tab shows the submitted Watch icon and five 416 × 496 screenshots per locale.
- [ ] Submission remains manual after final App Store Connect review.
