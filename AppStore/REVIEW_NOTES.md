Socket Buddy has no accounts, sign-in, or login of any kind — every screen is reachable
immediately after install. There is no demo account because none is needed.

IN-APP PURCHASE
"Socket Buddy Premium" (com.posix88.voltly.premium, non-consumable, $4.99) unlocks: saving more
than three countries, more than one trip, more than one device checked per trip, camera
device-label scanning, and two of the three home-screen/lock-screen widgets. The free tier
includes full country browsing, home-country compatibility guidance everywhere, three saved
countries, and one trip with one device checked.
To reach the paywall for testing, any of:
• Countries tab → swipe a row left and tap the star, four times (the fourth is paywalled)
• Trips tab → "+" with one upcoming trip already saved
• Trips tab → open a trip → "Add device" with one device already on it
• Trips tab → open a trip → "Add device" → "Scan device label"

CAMERA USAGE
The camera is used only to read the voltage/frequency printed on a device's label (e.g. a
charger's "INPUT: 100-240V 50/60Hz" text), via VisionKit's on-device text recognition. A transient
image may be captured and processed in memory for Apple Intelligence interpretation, but it is
never saved or uploaded. Recognized text is parsed locally and the camera session ends immediately
after. Premium access is required. Reachable at Trips tab → open a trip → "Add device" → "Scan
device label."

ON-DEVICE AI (OPTIONAL)
On a device/OS combination that doesn't support Apple Intelligence, the label scanner
automatically falls back to plain on-device text recognition (Vision framework) instead —
functionality doesn't change, just how confidently it parses an unusual label layout. This is
expected behavior, not a bug, if Apple Intelligence is unavailable in your review environment.

ICLOUD SYNC
Saved countries, trips, and their packed devices sync via the user's own iCloud account
(NSUbiquitousKeyValueStore) — there is no backend server and no account system, so there is
nothing for us to host, and no account for a user to delete (Guideline 5.1.1(v) does not apply).

WIDGETS
Home Country, Favorite Country, and Next Trip widgets can be added via the standard iOS widget
gallery. Favorite Country and Next Trip widgets require Premium; Home Country does not. The
Favorite Country widget's country is chosen in Settings (Countries tab → gear → Widgets); the Next
Trip widget picks whichever saved trip is current — an in-progress one, otherwise the soonest
upcoming departure — so there is nothing for the user to configure on it.

SIRI AND SPOTLIGHT
Socket Buddy provides background Siri answers without opening the app. Reviewers can ask for a
country's voltage and plug types, check a device's voltage/frequency compatibility, or request
requirements for their current trip. Country entities are also indexed in Spotlight. Spoken
answers are available in English and Italian and use conservative wording when device or home
country information is incomplete.

PRIVACY
Anonymous product analytics are sent through Firebase Analytics. No account identity, precise
location, camera image, scanned label text, saved country, trip, or packed-device information is
sent to the developer. Travel preferences sync only through the reviewer's own iCloud account.
