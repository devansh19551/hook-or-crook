# Working on Hook or Crook

A short guide for teammates. No coding is needed for the Designer / Tester role.

## Using GitHub Desktop (no commands)

1. **Clone** the repository once: File > Clone repository > pick `hook-or-crook`.
2. Before you start work, click **Fetch origin** and then **Pull** to get the latest version.
3. Add or change files (for example, put new icons in `assets/`).
4. In GitHub Desktop, write a short summary like `Add inbox icons`, then click **Commit**.
5. Click **Push origin** so everyone else gets your changes.
6. Do not edit the same file as someone else at the same time. Say so in the team chat first.

## Folder rules

| You are adding... | Put it in |
| --- | --- |
| Icons, images, logo | `assets/` (PNG or SVG) |
| Sounds | `assets/` (OGG) |
| New scam or genuine messages | The shared Google Sheet, not this repo. The Developer exports them into `data/scenarios.json`. |
| Bug reports | The "Bugs" tab of the shared sheet |

## Writing a scenario

Follow the columns in the README. Rules:

1. About 1 in 3 messages should be genuine, so players do not learn to ignore everything.
2. Base each scam on a real pattern (news, RBI or CERT-In advisories, the cybercrime portal), never on a real victim.
3. Use fictional names, phone numbers and links. Never put a working scam link in the game.
4. Bigger losses for bigger mistakes: clicking a link is small, sharing an OTP or UPI PIN is big.
5. Every scam needs 2-3 visible red flags, a one-line explanation, and a real-world fix (1930 helpline, cybercrime.gov.in).

## Testing a build

1. Install the APK, play at least 15 messages.
2. Note anything confusing, broken or unfair in the Bugs tab: what you did, what you expected, what happened, phone model, screenshot.
3. Rate the build: was it fun (1-5), did you learn something, would you play again tomorrow?

## For the Developer: Android export (once per machine)

1. Install OpenJDK 17 and the Android SDK command-line tools.
2. In Godot: Editor > Editor Settings > Export > Android, set the SDK and Java paths.
3. Project > Install Android Build Template, then Project > Export > Add > Android.
4. Make a debug keystore for test builds. **Keep it outside the repo.**
