# Socket Buddy — fastlane

Automates the build → sign → upload steps for shipping Socket Buddy. Everything one-time and manual
(paying for the Apple Developer Program, creating the app record in App Store Connect, creating
the `com.posix88.voltly.premium` in-app purchase, filling in App Privacy answers, writing the
privacy policy) is **not** automated here on purpose — see `AppStore/LAUNCH_PLAN.md` §1 for that
checklist. This is for everything *after* that's done.

(`skip_docs` is set in the Fastfile so running fastlane won't overwrite this file with its own
auto-generated lane docs — if you ever want that instead, remove `skip_docs` and lose this file.)

## One-time setup

1. **Install dependencies** (pinned via the root `Gemfile`, so everyone gets the same fastlane
   version):
   ```sh
   bundle install
   ```
1b. **Set a UTF-8 locale** — this machine's shell has `LANG=""`, which breaks fastlane's
   `xcrun simctl` parsing (`"'\xCA' on US-ASCII"`, `"xcrun simctl CLI broken"`). Add this to
   `~/.zshrc` (confirmed to actually fix it — setting it inside the Fastfile is too late, Ruby
   locks in its string encoding at interpreter startup):
   ```sh
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   ```
   Open a new terminal (or `source ~/.zshrc`) before running any lane below.
2. **Create an App Store Connect API key** — this is what lets `beta`/`release` talk to App
   Store Connect without an interactive Apple ID + 2FA prompt every time:
   - App Store Connect → Users and Access → Integrations → App Store Connect API → "+"
   - Role: **App Manager** is enough (don't need Admin)
   - Download the `.p8` file **immediately** — Apple only lets you download it once
   - Note the **Key ID** and **Issuer ID** shown on that page
3. **Set the required environment variables** (put them in your shell profile, or a local
   `.env` file — see below — never commit them):
   ```sh
   export ASC_KEY_ID="ABCD123456"
   export ASC_ISSUER_ID="11111111-2222-3333-4444-555555555555"
   export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_ABCD123456.p8"
   ```
   Fastlane also auto-loads a `fastlane/.env` file if one exists (gitignored — see
   `fastlane/.env.example` for the format) if you'd rather not touch your shell profile.

## Lanes

```sh
bundle exec fastlane test               # run the WorldPlugTests suite on a simulator
bundle exec fastlane beta                # test → bump build number → archive → upload to TestFlight
bundle exec fastlane release             # test → bump build number → archive → upload build + metadata + screenshots
                                          # (does NOT submit for review — that's a deliberate separate step,
                                          # flip `submit_for_review: true` in the Fastfile once you're sure)
bundle exec fastlane render_screenshots  # render Scripts/screenshots/captions.json into AppStore/Screenshots/ (local only, no upload)
bundle exec fastlane upload_metadata     # push ONLY fastlane/metadata/{en-US,it}/ to App Store Connect
bundle exec fastlane upload_screenshots  # push ONLY AppStore/Screenshots/{en-US,it}/ to App Store Connect
bundle exec fastlane metadata            # convenience: upload_metadata + upload_screenshots together
```

`upload_metadata`/`upload_screenshots`/`metadata` all skip the binary — none of them build or touch
TestFlight. Run `render_screenshots` first if `AppStore/Screenshots/{en-US,it}/` is stale.

## What's NOT handled here

- **Code signing**: the project currently uses Xcode's automatic signing (no `match`, no manual
  profiles) — `build_app` passes `-allowProvisioningUpdates` so Xcode can refresh profiles
  non-interactively. This is fine for a solo developer on one Mac; if you add CI or a second
  machine later, switch to `match` (syncs certs/profiles via a private git repo) rather than
  fighting "profile doesn't exist on this machine" errors.
- **The in-app purchase itself** (`com.posix88.voltly.premium`) — created and priced once in App
  Store Connect, not something `deliver` touches.
- **App Privacy answers, age rating, category** — one-time App Store Connect settings, not worth
  automating for a single app that won't change these often.
- **Submitting for review** — `release` uploads everything but leaves `submit_for_review: false`
  on purpose, so hitting "submit" is always a deliberate action you take in App Store Connect (or
  by flipping that flag once you're confident) — not something that happens as a side effect of
  running a lane.
