# DECISIONS.md

> Settled architectural decisions. **Append-only.** Never edit or delete past entries (one exception: `Status` field of a superseded entry).
> If a decision is reversed, append a new entry with `Supersedes: #NNNN`.

## How to use this file
- Read before contradicting any documented pattern.
- New decisions are added with the next sequential number.
- Each entry has: number, title, date, status, context, decision, consequences, optional `Supersedes`.

## Status values
- `Proposed` — under discussion
- `Accepted` — current
- `Superseded by #NNNN` — replaced by a later decision
- `Deprecated` — no longer applies but no replacement

---

## 0001 — Project initialized

**Date:** 2026-07-05
**Status:** Accepted
**Context:** Project scaffolded with the project-ninja skill.
**Decision:** Establish `AGENTS.md` and `docs/` as the source of truth for AI agent context. Cross-references owned per `references/cross-references.md` in the project-ninja skill.
**Consequences:** All AI tools (Claude Code, Antigravity, Codex, Cursor) read `AGENTS.md`. Decisions affecting the codebase land here.

---

## 0002 — Local Storage, Vanilla Extension and Mock Simulation

**Date:** 2026-07-05
**Status:** Accepted
**Context:** We need to build a Chrome Extension dashboard and an Android app showing electricity accounts, balances, slabs, and prediction forecasts. The app has no external database, and building real scrapers for all electric companies is prone to breaking due to captchas and dynamic page changes.
**Decision:**
1. **Chrome Extension Stack:** Use vanilla HTML5, CSS3, and JavaScript (ES6). Avoid bundle/compile overhead to maintain immediate editability and absolute compliance with Chrome Extension sandboxing rules.
2. **Data Mocking/Simulation:** Implement a robust Simulation Adapter interface. This allows users to add mock accounts, input custom starting balances and daily usage bounds, and manually trigger "simulated days" to witness balance decreases, billing slab increases, and warning alerts.
3. **Android App Local Alerts:** Use local Android WorkManager scheduling to run forecasting daily and emit native notifications locally.
**Consequences:**
- The extension runs instantly and is easily loadable from Chrome's Extension manager without building first.
- The user can test all features (billing slabs, progress bars, low-balance warnings) interactively in both environments using simulated metrics, while keeping code structures ready for future real scrapers.
- No network permissions are required for databases, enhancing privacy.

---

## 0003 — Filament Style System & Batti Renaming

**Date:** 2026-07-08
**Status:** Accepted
**Context:** We need to align both the Chrome extension and the Android companion app with the new visual brand identity and specifications: renamed to "Batti", using the "Filament" style system, and eliminating neons, glassmorphism, and dynamic coloring.
**Decision:**
1. **Renaming:** Rename the product from "Boner Mohis" to "Batti" in all public files, manifests, titles, and resources (e.g. `manifest.json`, `strings.xml`).
2. **Filament Styling:** Implement the Warm Paper (#F9F6F0) light mode, Warm-Dark (#1C1914) dark mode, 1px border (#E2DCCF/#38342C), and Ember Orange (#B25409) primary accent and warnings.
3. **Typography:** Use Space Grotesk (Medium) for large headers/balance numbers, DM Sans for content/body, and DM Mono for tabular data.
4. **Jetpack Compose Google Fonts:** Integrate the first-party `androidx.compose.ui:ui-text-google-fonts` library in Android to fetch the required fonts dynamically at runtime, avoiding APK bloat.
5. **No Glassmorphism/Gradients:** Strip out all neons, background gradients, dynamic Material3 coloring, and translucent glassmorphism in favor of clean card elements and custom 1.5px stroke outline icons.
6. **Segmented Indicator:** Replace continuous progress bars with a 5-segment ChargeBar indicator to visualize the remaining forecast balance.
**Consequences:** Both extension and Android apps display cohesive branding, adhere to calm voice criteria, present high visual quality, and utilize dynamic Google Fonts loading.

---

## 0004 — Reverting name to Boner Mohis

**Date:** 2026-07-09
**Status:** Accepted
**Context:** The brand name has been reverted from "Batti" back to "Boner Mohis" per user feedback.
**Decision:** Change manifest name, app labels, and headers back to "Boner Mohis" while preserving all the new Filament Style System design components, colors, and typography layouts.
**Consequences:** The application retains its classic naming "Boner Mohis" with the subtitle "Electricity forecaster" on both platforms, while keeping the visual layout updates.

---

## 0005 — Add url_launcher and Maintainer Donation Links

**Date:** 2026-08-28
**Status:** Accepted
**Context:** We need to support opening external maintainer support and donation links from within both the Android companion app and Chrome Extension UI.
**Decision:**
1. Add `url_launcher` package to Flutter `pubspec.yaml` to allow opening external donation URLs.
2. Add Maintainer Donation / Support links with project-specific UTM tracking parameters to both the Chrome Extension UI and Android companion app UI.
**Consequences:** Users can click the support/donation button in the app bar/header or dashboard banner to open the maintainer donation page.

