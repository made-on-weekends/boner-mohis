# AGENTS.md

> Briefing packet for AI coding agents (Claude Code, Antigravity, Codex, Cursor, Gemini CLI, etc.).
> Humans should read README.md instead.

## Rules of engagement

These rules are the agent's first read every session. Keep this list short — 5–10 rules, each one absolute.

1. **Do** follow conventions documented in this file and the relevant `docs/` file. **Don't** invent new conventions silently.
2. **Do** check `docs/DECISIONS.md` before contradicting any documented pattern.
3. **Do** read `docs/SECURITY.md` Hard Rules before touching auth, data handling, or any input-validation code.
4. **Do** ask before expanding scope beyond `docs/PRODUCT.md`.
5. **Don't** edit files in the do-not-touch zones below.
6. **Don't** introduce a new third-party dependency without a `docs/DECISIONS.md` entry.
7. **Do** use modern vanilla HTML, CSS, and ES6+ JavaScript for the Chrome extension popup. Ensure it has visual animations, HSL colors, glassmorphism, and a highly responsive dashboard interface.
8. **Do** implement a modular adapter structure for fetching data from electricity providers, so we can support mock simulation and extend to scraper/API implementations.

## Stack

- Language(s): JavaScript (ES6+), Kotlin
- Framework(s): Chrome Extension (Manifest V3), Jetpack Compose (Android)
- Backend: None (local client-only architecture)
- Database: `chrome.storage.local` (Extension), SQLite via Room (Android)
- Hosting / runtime: Google Chrome Browser, Android OS
- Package/dependency manager: `npm` (for development environment setup and helper scripts)
- Language version: Node.js >= 18, JDK >= 17

## Commands

```bash
# Setup / installation (when using node-based tooling)
npm install

# Build / bundle extension (not needed for vanilla, but useful if doing validation)
# No build required for Chrome Extensionpopup - it is loaded directly from workspace

# Lint / format (if package.json contains prettier/eslint)
npm run lint
npm run format
```

## Conventions

- **Design Specifications:** All design files (including `docs/DESIGN.md` and its derived/override mirror files) must strictly adhere to the Google Labs `DESIGN.md` format specification (combining machine-readable YAML frontmatter with standard markdown sections). Verify correctness using `npx @google/design.md lint <filepath>`.
- **File Structure:**
  - `/extension` -> Chrome extension files (manifest.json, popup.html, popup.js, popup.css, etc.)
  - `/android` -> Android Studio Kotlin/Room project files
  - `/docs` -> Canonical project documentation
- **Variable/Storage naming:**
  - Account object: `{ id, provider, accountNo, nickname, balance, lastUpdated, usageThisMonth, yesterdayUsage, currentSlab, slabLimit, slabUsage }`
- **Calculations & Forecasting:**
  - Days Remaining = `balance / yesterdayUsage` (in local currency, if usage > 0)
  - Slab percentage = `(slabUsage / slabLimit) * 100`

## Project-specific rules

- "All calculations for remaining balance forecasting must handle zero-usage and negative-balance edge cases gracefully (e.g. display '-- days remaining' if yesterday's usage is 0)."
- "Electricity account credentials/numbers are stored in `chrome.storage.local` and must not be exposed to external domains."

## Do-not-touch zones

- `node_modules/`
- `.git/`
- Generated Android build outputs (`build/`, `.gradle/`, etc.)

## Where to look

- Architecture overview: `docs/ARCHITECTURE.md`
- Settled decisions: `docs/DECISIONS.md` (read before contradicting any pattern)
- Security rules: `docs/SECURITY.md` (Hard Rules at top)
- Product Scope: `docs/PRODUCT.md`
- Schema: `docs/SCHEMA.md`
- Database: `docs/DATABASE.md`
- Tariff rates & slab logic: `docs/TARIFF.md` (**read before touching any rate or slab calculation**)
