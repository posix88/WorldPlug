# Socket Buddy — App Store Launch Plan

**Socket Buddy** is the App Store / marketing name — "Voltly" turned out to already be taken. Internally the bundle ID, App Group, URL scheme (`voltly://`), and Swift type names (`VoltlyApp`, `VoltlyWidgets`, `VoltlyDeepLink`, …) all still say "Voltly" — none of that is user-visible or checked against other apps, so it was left alone. See [CLAUDE.md](../CLAUDE.md) for the full internal/external naming split.

Bundle ID `com.posix88.Voltly` · Primary category **Travel** (already set via `INFOPLIST_KEY_LSApplicationCategoryType`) · One IAP: `com.posix88.voltly.premium` ("Socket Buddy Premium", non-consumable, $4.99).

This plan assumes the app itself is code-complete (see the correctness review above/[CLAUDE.md](../CLAUDE.md) for the outstanding bugs — fix at least items 1–3 there before submitting). Everything below is what's left to actually get to "Ready for Sale."

---

## 1. App Store Connect setup checklist

- [ ] Create the app record in App Store Connect (bundle ID `com.posix88.Voltly`), if not already created.
- [ ] Create the in-app purchase `com.posix88.voltly.premium` as **Non-Consumable**, display name "Socket Buddy Premium", price tier matching $4.99 — this must be created and in "Ready to Submit" state *before* you submit the app binary that references it, or the binary validation / review can stall.
- [ ] Fill in the two localizations for the IAP exactly as already drafted in [`WorldPlug/Resources/StoreKit/Voltly.storekit`](../WorldPlug/Resources/StoreKit/Voltly.storekit): EN "Unlock saved countries, trips, and premium widgets.", IT "Sblocca paesi salvati, viaggi e widget premium."
- [ ] Add **App Privacy** ("nutrition label") answers — see §5 below.
- [ ] Answer the **Age Rating** questionnaire — nothing in the app suggests anything above 4+ (no user-generated content, no unrestricted web access, no gambling; camera use is for label-scanning only, not photo capture/sharing).
- [ ] Set primary category **Travel**; consider secondary category **Utilities**.
- [ ] Add support URL and marketing URL (a simple landing page or even a GitHub Pages README works for a v1 — App Store requires a working support URL).
- [ ] Add a privacy policy URL (**required** because you collect analytics data and sync via iCloud — see §5; a one-page policy is enough, several free generators exist, or write ~1 page by hand covering Firebase Analytics + iCloud KVS + no ad tracking).
- [ ] Set up App Store Connect **TestFlight** internal testing build first, sanity-check the paywall against a **Sandbox Apple ID**, and confirm `Transaction.updates` + `AppStore.sync()` behave against the sandbox before submitting for review (StoreKit sandbox behaves differently enough from production that this is worth doing even solo).
- [ ] Localize the App Store *listing itself* for both `en-US` and `it-IT` (App Store Connect lets you pick which locales to support — add both).

## 2. Metadata copy — English (`en-US`)

**App name** (≤30 chars) — already set in `fastlane/metadata/en-US/name.txt`:
- `Socket Buddy: Plugs & Voltage` (29 chars)

**Subtitle** (≤30 chars):
> Plugs, voltage, travel safety

**Promotional text** (≤170 chars, editable anytime without a new binary):
> Never get stuck with the wrong plug again. Check compatibility for 200+ countries, scan device labels, and plan your next trip — all offline.

**Keywords** (≤100 chars, comma-separated, no spaces — App Store Connect counts every character):
```
plug,adapter,voltage,socket,travel,converter,outlet,electricity,frequency,charger,abroad,trip
```

**Description** (≤4000 chars):
```
Traveling with the wrong plug or the wrong voltage can fry your charger — or worse. Socket Buddy tells you, in seconds, exactly what you need for any of 200+ countries: plug type, voltage, frequency, and whether your devices are safe to use as-is, with an adapter, or need a voltage converter.

WHAT SOCKET BUDDY DOES

• Browse plug types & sockets for 200+ countries — clear diagrams, voltage, frequency, and every plug standard in use there.
• Set your home country once and get instant compatibility badges everywhere: Compatible, Adapter needed, or Converter required.
• Trip Check — add every device you're packing (phone charger, hair dryer, CPAP, laptop, camera gear…) and get a per-device safety verdict for your destination.
• Scan a device's label with your camera — Socket Buddy reads the voltage and frequency printed on the label for you, using on-device text recognition and Apple Intelligence where available. Nothing leaves your phone.
• Save your favorite countries and plan your Next Trip, with home-screen and lock-screen widgets that always show the right plug at a glance.
• Ask Siri or search Spotlight — "Open Japan in Socket Buddy" or "What's my home country's plug type" just works.
• Works fully offline. Your data syncs privately across your own devices via iCloud — never shared with anyone else.

WHY SOCKET BUDDY

Socket Buddy was built by a solo traveler tired of guessing whether a socket would fit, or whether "230V" was going to be a problem. It's fast, offline-first, and doesn't try to be anything other than the plug-and-voltage app it needs to be.

SOCKET BUDDY PREMIUM (one-time purchase, no subscription)

• Save unlimited countries
• Plan your Next Trip and get unlimited Pack Checks
• Unlock the Favorite Country and Next Trip widgets

The core country browser, compatibility checks, and camera label scanning are free forever. Premium is a single $4.99 purchase — no subscription, no recurring charge, no ads, ever.

Questions or feedback? We'd love to hear from you.
```

**What's New (first version)**:
> Welcome to Socket Buddy! Browse plug types and voltage for 200+ countries, run a Trip Check on everything you're packing, scan device labels with your camera, and keep your favorite countries and next trip one glance away with widgets.

## 3. Metadata copy — Italian (`it-IT`)

**Nome app** (≤30 caratteri) — già impostato in `fastlane/metadata/it-IT/name.txt`:
- `Socket Buddy: Prese in viaggio` (30 caratteri)

**Sottotitolo** (≤30 caratteri):
> Prese, voltaggio, sicurezza

**Testo promozionale** (≤170 caratteri):
> Non restare mai più senza corrente in viaggio: compatibilità per oltre 200 paesi, scansione etichette e pianificazione viaggi, tutto offline.

**Parole chiave** (≤100 caratteri, separate da virgola, senza spazi):
```
spina,adattatore,voltaggio,presa,viaggio,convertitore,elettricità,frequenza,caricabatterie,estero
```

**Descrizione** (≤4000 caratteri):
```
Viaggiare con la spina sbagliata o il voltaggio sbagliato può bruciare il tuo caricabatterie — o peggio. Socket Buddy ti dice, in pochi secondi, esattamente cosa ti serve per oltre 200 paesi: tipo di presa, voltaggio, frequenza e se i tuoi dispositivi sono sicuri da usare così come sono, con un adattatore, o se serve un convertitore di tensione.

COSA FA SOCKET BUDDY

• Sfoglia i tipi di presa e spina per oltre 200 paesi — schemi chiari, voltaggio, frequenza e tutti gli standard di spina in uso.
• Imposta il tuo paese di origine una volta sola e ottieni badge di compatibilità istantanei ovunque: Compatibile, Adattatore necessario o Convertitore necessario.
• Trip Check — aggiungi ogni dispositivo che porti in valigia (caricabatterie, asciugacapelli, CPAP, laptop, attrezzatura fotografica…) e ottieni un verdetto di sicurezza per ogni dispositivo in base alla tua destinazione.
• Scansiona l'etichetta di un dispositivo con la fotocamera — Socket Buddy legge voltaggio e frequenza stampati sull'etichetta usando il riconoscimento testo on-device e Apple Intelligence dove disponibile. Nessun dato lascia il tuo iPhone.
• Salva i tuoi paesi preferiti e pianifica il tuo Prossimo viaggio, con widget per la schermata Home e il Lock Screen che mostrano sempre la presa giusta a colpo d'occhio.
• Chiedi a Siri o cerca con Spotlight — "Apri Giappone in Socket Buddy" o "Qual è la presa del mio paese" funziona subito.
• Funziona completamente offline. I tuoi dati si sincronizzano in privato tra i tuoi dispositivi tramite iCloud — mai condivisi con nessun altro.

PERCHÉ SOCKET BUDDY

Socket Buddy è nato dall'esigenza di un viaggiatore stanco di indovinare se una presa sarebbe entrata, o se "230V" sarebbe stato un problema. È veloce, funziona offline ed è pensato per fare bene una cosa sola: dirti tutto su prese e voltaggio.

SOCKET BUDDY PREMIUM (acquisto una tantum, nessun abbonamento)

• Salva un numero illimitato di paesi
• Pianifica il tuo Prossimo viaggio e ottieni Trip Check illimitati
• Sblocca i widget Paese preferito e Prossimo viaggio

L'esplorazione dei paesi, i controlli di compatibilità e la scansione delle etichette con la fotocamera sono gratuiti per sempre. Premium è un unico acquisto da 4,99 € — nessun abbonamento, nessun addebito ricorrente, mai pubblicità.

Domande o suggerimenti? Ci farebbe piacere sentirti.
```

**Novità (prima versione)**:
> Benvenuto in Socket Buddy! Sfoglia tipi di presa e voltaggio per oltre 200 paesi, esegui un Trip Check su tutto ciò che porti in valigia, scansiona le etichette dei dispositivi con la fotocamera e tieni sempre a portata di sguardo il tuo paese preferito e il prossimo viaggio grazie ai widget.

> **Note on the Italian copy**: machine-quality but idiomatic; a native-speaker pass (you) before submitting is still worth 10 minutes, especially on the app name/subtitle since those are the highest-visibility strings and can't be A/B tested cheaply.

## 4. Screenshots

`AppStore/Screenshots/{raw,en-US,it-IT}/` already exist but are **empty** — nothing has been captured yet. Apple changes required screenshot sizes periodically — treat the table below as a starting point and let App Store Connect's upload screen be the source of truth at submission time:

| Device | Size (px) | Required? |
|---|---|---|
| iPhone 6.9" (17 Pro Max / 16 Pro Max class) | 1320 × 2868 (or 2868 × 1320 landscape) | **Yes** — this is the baseline set Apple requires |
| iPhone 6.5"/6.7" | 1290 × 2796 | Optional if 6.9" set supplied and you don't need older-device-specific shots |
| iPad 13" (12.9"/13" class) | 2064 × 2752 (portrait) | **Yes**, since `TARGETED_DEVICE_FAMILY = "1,2"` (universal) — Apple requires iPad screenshots for any app that supports iPad |

You need **3–10 screenshots per device size per locale** (5 is a good target). Suggested shot list, matched to what actually exists in the app today:

1. **Countries tab** — the list with a few flags visible and a compatibility badge showing, ideally with the home-country banner set (shows the "instant compatibility" value prop immediately).
2. **Country Detail** — a popular destination (e.g. Japan or UK — visually distinct plug shapes) showing plug diagrams + voltage/frequency + the map.
3. **Trip Check result** — a packed-devices list with a mix of ✅ Compatible / ⚠️ Adapter needed verdicts, to sell the "so you don't fry your charger" hook.
4. **Device label scanner** — the camera view mid-scan with recognized text highlighted (this is the most differentiated, "wow" feature — put it early, not last).
5. **Saved Countries + Next Trip** (Premium) — shows the paywall value without being the paywall itself.
6. *(optional 6th)* — a **widget gallery** shot (Home Country / Favorite Country / Next Trip widgets on a Home Screen) — widgets sell well as a screenshot and you already have three widget families built.

### Captioning: use the on-brand renderer, not `frameit`

`Scripts/screenshots/` has a working, on-brand captioning pipeline — an HTML/CSS template using
Socket Buddy's actual colors (the cosmic mesh gradient from `AppMeshBackground.swift`, the volt-tint
gold accent) rendered to a pixel-perfect PNG via headless Chrome, instead of `fastlane frameit`'s
flat-color/system-font look. Two real examples are already rendered in
`Scripts/screenshots/out/en-US/` from the actual running app (Countries list, and a Trip Check
"do not use without a converter" verdict) — open them to see the actual output before doing your
own. Full usage in `Scripts/screenshots/README.md`, including how to wire it up behind `fastlane
snapshot` once a UI Testing target exists for full multi-device/locale automation.

Process:
- [ ] Capture raw screenshots — either by hand (`xcrun simctl io booted screenshot`, on an iPhone
      17 Pro Max–class simulator and an iPad 13" simulator, in English and Italian) or via
      `fastlane snapshot` once set up (README has the setup steps) — into
      `Scripts/screenshots/raw/`.
- [ ] Run each through `node render.mjs --input ... --caption "..." --output ... --width ...
      --height ...` (README has the full flag list) into `Scripts/screenshots/out/{en-US,it-IT}/`.
- [ ] Write one short, punchy caption per shot in both languages — reuse the shot list above as
      your caption ideas (e.g. "200+ countries, one glance" for #1, "Know before you plug in" for
      #3) rather than starting from a blank page.
- [ ] Copy the final PNGs from `Scripts/screenshots/out/` into `AppStore/Screenshots/{en-US,it-IT}/`
      for upload — the `out/` folder is gitignored scratch space, `AppStore/Screenshots/` is where
      the actual submission assets should live.

## 5. App Privacy ("nutrition label")

Based on what's actually in the code (`Analytics` package → Firebase Analytics only; no Crashlytics, no ads SDK, no third-party trackers found in `Package.swift`/target dependencies):

| Data type | Collected? | Linked to identity? | Used for tracking? |
|---|---|---|---|
| Product interaction / usage data (your `AnalyticsEvent` cases — onboarding, saves, etc.) | Yes (Firebase Analytics) | No (unless you've enabled `setUserID`/`setUserProperty` with identifying data — check `AnalyticsTracker.swift`, it doesn't appear to) | No |
| Identifiers (Firebase App Instance ID) | Yes, automatically by the SDK | No | No |
| Diagnostics (crash/performance, if Firebase Analytics' default crash reporting is on) | Possibly — confirm in Firebase console settings | No | No |
| Location | **No** — `CountryMapGeocoder` does a forward geocode of a *country name*, it never reads the user's device location | — | — |
| User content (saved countries, next trip, pack devices) | Yes, but stored **only** in the user's own iCloud account (`NSUbiquitousKeyValueStore`) — not sent to your servers | Yes (tied to their Apple ID for their own sync) | No |
| Camera | Used locally only (label scanning); no images are uploaded or stored | — | — |

Answer "Data Used to Track You": **No** (there's no IDFA/ATT usage found anywhere in the codebase — confirm no `AppTrackingTransparency` import exists, which matches what was found).

Action items:
- [ ] Double-check the Firebase Analytics initialization (`FirebaseAnalyticsTracker.configure()`) for any `Analytics.setUserID`/custom-dimension calls that might attach identity — none were found in this pass, but re-verify against the actual `AnalyticsTracker.swift` contents before answering App Store Connect's questionnaire, since incorrect answers here are an App Review rejection reason and a legal exposure, not just a formality.
- [ ] Write the 1-page privacy policy covering: Firebase Analytics (anonymous usage analytics, no ad targeting), iCloud sync (user's own data, Apple's iCloud, not your servers), no data sold/shared with third parties, no location collected, camera used on-device only.

## 6. Suggested pre-submission order of operations

1. ~~Fix the top items in [CLAUDE.md](../CLAUDE.md)'s "Known issues"~~ — done; see that file's log.
2. Create the IAP in App Store Connect and verify a Sandbox purchase + restore end-to-end on a real device.
3. Write and host the privacy policy; fill in App Privacy answers.
4. Capture and caption screenshots (§4) — pipeline + two real examples already in `Scripts/screenshots/`.
5. Fill in metadata (§2/§3) — already drafted into `fastlane/metadata/{en-US,it-IT}/`, ready for `fastlane release` to push (see below); do a native-speaker pass on the Italian copy first.
6. Generate an App Store Connect API key and set up `fastlane/.env` — see `fastlane/README.md`.
7. `bundle exec fastlane beta` — runs the test suite, bumps the build number, archives, and uploads to TestFlight. Install it on a real device yourself first; StoreKit sandbox, widgets, and the camera permission prompt all behave subtly differently on-device than in the simulator.
8. `bundle exec fastlane release` once TestFlight checks out — uploads the build plus metadata and screenshots to App Store Connect, but leaves `submit_for_review: false` on purpose. Review everything in App Store Connect's UI, then either flip that flag in `fastlane/Fastfile` or hit submit manually — a deliberate last step, not a side effect of running a lane.
