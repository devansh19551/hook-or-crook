# Hook or Crook

A free, mobile-first life-simulator game that teaches scam awareness. Your phone keeps receiving messages, calls and offers. Some are real opportunities, some are scams. Trust the wrong one and you lose your money; spot the scams and take the real chances and you build up to a bike, a car and a house.

Status: **first playable prototype** (Godot 4, Android first, iOS later).

## What works now

- **Title menu:** Continue a saved life, start a new one, or play the quick quiz
- **Life mode:** a fake phone inbox showing one message at a time (SMS, WhatsApp, call, email, QR, ad) with three choices: **Trust it / Ignore it / Report it**
- Money counter, daily salary, streaks and ranks (Easy Target, Alert, Sharp, Cyber Guardian, Scam Hunter)
- Three goals that unlock as your money grows: **Bike, Car, House**
- A "What just happened?" card after every decision with the red flags and the real-world fix (1930, cybercrime.gov.in)
- Progress is saved on the phone automatically
- **Quick Quiz:** 10 random "Scam or Legit?" questions with explanations and a saved best score
- 30 scenarios (20 scams, 10 genuine) and 15 quiz questions, all in `data/`

## Run it

1. Open **Godot 4** and click **Import**.
2. Select this folder's `project.godot`.
3. Press **F5** (Play). The game window is portrait (540 x 960) like a phone.

The project is set to Godot **4.3** with the GL Compatibility renderer. A newer 4.x editor will offer to upgrade the project on first open; that is fine.

## Project layout

| Path | What lives there | Mostly edited by |
| --- | --- | --- |
| `scripts/menu.gd` | Title screen | Developer |
| `scripts/life.gd` | Life mode: messages, money, goals, ranks, saving | Developer |
| `scripts/quiz.gd` | Quick Quiz mode | Developer |
| `scripts/ui.gd` | Shared colours, buttons, labels, money formatting | Developer |
| `scripts/save_store.gd` | Saves and loads progress on the phone | Developer |
| `scenes/` | `menu.tscn` (starts the game), `life.tscn`, `quiz.tscn` | Developer |
| `data/scenarios.json` | Every scam and genuine message | Content |
| `data/goals.json` | Bike, Car, House: names and prices (tune the game balance here) | Content / Developer |
| `data/quiz.json` | Quick Quiz questions | Content |
| `assets/` | Icons, images, sounds | Designer |
| `CONTRIBUTING.md` | Git and scenario-writing guide for teammates | Everyone |

## Scenario format

Each scenario in `data/scenarios.json` matches one row of the shared Google Sheet:

| Field | Meaning |
| --- | --- |
| `id` | Unique short name, e.g. `kyc_01` |
| `channel` | `sms`, `whatsapp`, `call`, `email`, `qr` or `ad` |
| `sender` | Who it appears to come from |
| `text` | The message the player reads |
| `is_scam` | `true` or `false` |
| `right_action` | `accept` (genuine), `ignore` or `report` (scams) |
| `money_if_wrong` | Rupees lost if a scam is trusted (negative number) |
| `money_if_right` | Rupees earned for the right move (reporting a scam, or taking a genuine offer) |
| `red_flags` | List of short clues shown on the result card |
| `explanation` | 1-2 sentences for the "What just happened?" card |
| `real_fix` | What to do in real life (leave empty for genuine messages) |
| `difficulty` | `easy`, `medium` or `hard` |

All brands, senders, numbers and links in the scenarios are fictional.

## Rules for this repo

- **Never commit** keystores, passwords or API keys (`.gitignore` blocks the common ones).
- Share APKs through GitHub Releases, not by committing them.
- Keep real names, phone numbers and working scam links out of the game.

## Roadmap

1. Done: repo, playable inbox, 30 scenarios, three goals, ranks, streaks, saving, menu, Quick Quiz
2. Next: Android export and a signed test APK, then 10 playtesters
3. Then: a 60-second timer for the quiz, daily scam drop, sounds, nicer art, share button
4. Later: scenario CSV converter, leaderboards and Scam Lab (needs a backend), iOS
