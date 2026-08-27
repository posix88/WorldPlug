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
network's TLS proxy) — `render.mjs` points at the system Google Chrome install instead. If your
Chrome lives somewhere other than `/Applications/Google Chrome.app`, set
`PUPPETEER_EXECUTABLE_PATH` before running.

## Usage

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

Edit `template.html` directly for anything structural (layout, colors, adding a subhead line,
switching to a light-mode gradient) — it's plain CSS, no build step.

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
4. One Fastlane lane chains both steps — capture, then composite:

   ```ruby
   desc "Capture and caption App Store screenshots"
   lane :screenshots do
     snapshot
     Dir.glob("Scripts/screenshots/raw/**/*.png").each do |raw_path|
       # map raw_path -> caption text (e.g. via captions.json) and call render.mjs per file
     end
   end
   ```

   The loop body depends on how you want to key captions to screenshots — a `captions.json`
   keyed by screenshot name (see the shot list in `AppStore/LAUNCH_PLAN.md`) plus a small `sh`/`node`
   driver script is the straightforward way; ask for it built out once the UI test target exists,
   since it's easier to get the file-naming convention right against real `snapshot` output than
   to guess it in advance.
