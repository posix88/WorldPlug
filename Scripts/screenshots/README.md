# Socket Buddy screenshot pipeline

Composites raw device screenshots + captions into finished, on-brand App Store screenshots —
using Socket Buddy's own colors (the cosmic mesh gradient from `AppMeshBackground.swift`, the volt-tint
gold accent) instead of a generic frame + flat background. See two real examples already rendered
in `out/en-US/`.

## Why this exists instead of `fastlane frameit`

`frameit` frames + captions screenshots, but only with a flat background color and the system
font — it can't reproduce Socket Buddy's actual visual identity. This does the same job (raw screenshot
in → captioned marketing image out) with full CSS control instead, driven by headless Chrome via
Puppeteer so it's just as scriptable/batchable as `frameit` — it's a drop-in replacement for that
one step, not a replacement for `fastlane snapshot`. See "Combining with fastlane snapshot" below.

## Setup (one-time)

```sh
cd Scripts/screenshots
PUPPETEER_SKIP_DOWNLOAD=true npm install
```

`PUPPETEER_SKIP_DOWNLOAD` skips Puppeteer's bundled-Chromium download (it fails behind this
network's TLS proxy) — the renderer points at the system Google Chrome install instead. If your
Chrome lives somewhere other than `/Applications/Google Chrome.app`, set
`PUPPETEER_EXECUTABLE_PATH` before running. (`bundle exec fastlane render_screenshots` runs this install
step automatically on first use — see "Batch rendering" below.)

## Batch rendering (recommended) — `captions.json` + `render-all.mjs`

The normal workflow: add a raw capture to `raw/`, add an entry to `captions.json` (device +
per-locale caption text), then render everything in one shot and copy the results straight into
`AppStore/Screenshots/`:

```sh
bundle exec fastlane render_screenshots
```

(or `node render-all.mjs` directly from this directory, if you just want `out/` populated without
the copy step). `captions.json` looks like this:

```json
{
  "devices": { "iphone": { "width": 1320, "height": 2868 } },
  "shots": [
    {
      "id": "01_countries",
      "raw": { "iphone": "countries_demo.png" },
      "captions": {
        "en-US": "200+ countries, one glance",
        "it": "Oltre 200 paesi, un solo sguardo"
      }
    }
  ]
}
```

Add a device (e.g. `"ipad": { "width": 2064, "height": 2752 }`) once you have a raw capture at
that resolution, and reference it in a shot's `raw` map — the renderer fans out over every
device × locale combination it finds captures/captions for.

**Current limitation**: there's only one raw capture per shot (captured in English), reused for
every locale — so an `it` render gets the Italian caption composited over a screenshot whose
on-screen app UI is still in English. The renderer prints a reminder about this every run. Fix it
per-shot by capturing the real screen with the simulator's language set to Italian and pointing
that shot's `raw` entry at the new file — no schema changes needed.

## One-off rendering — `render.mjs`

For a single image without touching `captions.json`:

```sh
node render.mjs \
  --input raw/countries.png \
  --caption "200+ countries, one glance" \
  --output out/en-US/01_countries.png \
  --width 1320 --height 2868
```

Required: `--input`, `--caption`, `--output`, `--width`, `--height` (use Apple's exact target
dimensions — see `AppStore/LAUNCH_PLAN.md` §4 for the current list; App Store Connect's upload
screen is the source of truth since Apple changes these periodically).

Optional: `--eyebrow "Socket Buddy"` (small label above the caption), `--caption-size <px>` (tune for
longer captions), `--shot-top <percent>` (where the screenshot starts, as % of canvas height —
raise it if a long caption wraps to 3 lines and starts crowding the frame).

Both `render.mjs` and `render-all.mjs` share their actual compositing logic via `lib.mjs`. Edit
`template.html` directly for anything structural (layout, colors, adding a subhead line,
switching to a light-mode gradient) — it's plain CSS, no build step, and both entry points pick
up the change automatically.

## Getting raw screenshots

Any raw PNG at the target device's native resolution works. Two ways to get them:

**From the Simulator directly** (what was used for the two examples in `out/en-US/`):
```sh
xcrun simctl io booted screenshot raw/my_screen.png
```
Boot the right simulator first (`xcrun simctl boot "iPhone 17 Pro Max"`), launch Socket Buddy, navigate
to the screen you want, then run the command above.

**From `fastlane snapshot`** — see below. Same `render.mjs` command either way; `snapshot` just
automates driving the simulator through every screen/device/locale instead of doing it by hand.

## Combining with fastlane snapshot

`snapshot` needs a UI Testing target, which this repo doesn't have yet. Adding one is safest done
in Xcode itself (File → New → Target → UI Testing Bundle) rather than hand-editing
`project.pbxproj`. Once you've added it:

1. Drop fastlane's `SnapshotHelper.swift` into the new UI test target (`fastlane snapshot init`
   generates it, or copy it from the fastlane repo).
2. Write a UI test that navigates to each screen and calls `Snapshot.snapshot("name")`:

   ```swift
   import XCTest

   final class VoltlyScreenshotTests: XCTestCase {
       func testCaptureScreenshots() {
           let app = XCUIApplication()
           setupSnapshot(app)
           app.launch()

           snapshot("01_countries")

           app.tabBars.buttons["Pack Check"].tap()
           snapshot("02_tripcheck")

           // ...remaining screens
       }
   }
   ```
3. Add a `Snapfile` (repo root or `Scripts/`):

   ```ruby
   scheme "WorldPlug"
   devices(["iPhone 17 Pro Max", "iPad Pro 13-inch (M4)"])
   languages(["en-US", "it-IT"])
   output_directory "./Scripts/screenshots/raw"
   clear_previous_screenshots true
   ```
4. Point `captions.json`'s shot entries at `snapshot`'s output filenames (it names files
   `<locale>/<device>-<name>.png` under `output_directory`), then `bundle exec fastlane
   screenshots` renders and copies them exactly as it does today for hand-captured raw
   screenshots — no changes needed to `render-all.mjs` or the `screenshots` lane itself, just to
   which files `raw/` (or wherever `snapshot` writes to) actually contains.
