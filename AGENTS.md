# AGENTS.md

> Briefing packet for AI coding agents (Claude Code, Antigravity, Codex, Cursor, Gemini CLI, etc.).
> Humans should read README.md instead.

## Rules of engagement

These rules are the agent's first read every session. Keep this list short — absolute and enforceable:

1. **Do** follow conventions documented in this file and the relevant `docs/` file. **Don't** invent new conventions silently.
2. **Do** check `docs/DECISIONS.md` before contradicting any documented pattern.
3. **Do** read `docs/SECURITY.md` Hard Rules before touching network calls, data storage, or input-validation code.
4. **Do** ask before expanding scope beyond `docs/PRODUCT.md`.
5. **Don't** edit files in the do-not-touch zones below.
6. **Don't** modify database tables or schema without updating `docs/SCHEMA.md` and adding safe migration handling in `AppDatabase`.
7. **Don't** introduce a new third-party dependency without a `docs/DECISIONS.md` entry.
8. **Do** enforce and conform to `.editorconfig` formatting rules (indentation: 2 spaces, line endings: LF, charset: UTF-8, trimmed whitespace) across all code and documentation.
9. **Do** run and conform to the project's linter and test commands (`flutter analyze`, `flutter test`, `npm run lint` in `extension-react`) before declaring work complete.

## Stack

- **Mobile App**: Flutter (Dart `^3.12.2`, Android target)
- **Browser Extension**: React 19, Vite 8, Oxlint (Chrome Manifest V3 target in `extension-react/`)
- **State Management**: `flutter_riverpod` (v2.5) for Flutter; React hooks for Extension
- **Database**: `sqflite` (v2.3) local SQLite database (`boner_mohis.db`)
- **Background Tasks**: `workmanager` (Android periodic task sync)
- **Notifications**: `flutter_local_notifications`
- **Networking**: `http` with custom `SecurityContext` in `desco_http_client.dart` pinning DigiCert Global G2 CA
- **Design & Theme**: Filament Design System (`lib/ui/theme/filament_theme.dart`), Google Fonts (Space Grotesk, DM Sans, DM Mono)

## Commands

```bash
# Flutter Mobile App
flutter pub get               # Install dependencies
flutter analyze               # Run Dart static analyzer
flutter test                  # Run unit & widget tests
flutter run                   # Run app on connected device/emulator
flutter build apk             # Build Android release APK
flutter build bundle          # Build Flutter asset bundle

# Browser Extension (extension-react/)
npm ci --prefix extension-react        # Install extension dependencies
npm run lint --prefix extension-react  # Lint extension source with oxlint
npm run build --prefix extension-react # Build extension bundle into extension/
npm run dev --prefix extension-react   # Run Vite development server
```

## Conventions

- **Code Style & Formatting (.editorconfig & Linters):** Strict adherence to `.editorconfig` (2 spaces indentation, LF) and configured linters (`flutter analyze`, `oxlint`).
- **Design Specifications:** All design files must conform to the Google Labs `DESIGN.md` specification in `docs/DESIGN.md`. Brand assets reside canonically at `/home/asif/Documents/brands/boner-mohis/`.
- **Bilingual & Typography Rules:**
  - **Bangla UI copy:** Primary user interface labels and headings are in Bangla.
  - **Latin numerals always:** Balance (৳), consumption (kWh), timestamps, account numbers, and meter IDs must strictly use Latin numerals (`DM Mono` / `DM Sans`), never Bengali numerals.
  - **Bangla Leading:** Bangla typography requires ~+0.15 additional line-height over Latin equivalents to avoid matra and vowel collisions.
- **Iconography & Mark:**
  - The toolbar ember mark is a single drawing with 3 recolored states (`ok`, `low`, `critical`).
  - No battery icons, neon lightning bolts, or 3D house renders.
- **DESCO TLS Pinning:** All outbound calls to DESCO prepaid APIs (`prepaid.desco.org.bd`) must route through `createDescoHttpClient()` to avoid missing intermediate CA handshake failures on Android.

## Project-specific rules

- **Local-first privacy:** No central telemetry, tracking, or cloud backend. All account credentials, meter numbers, and usage histories remain strictly on the local device.
- **Fail-safe offline state:** If DESCO API is unreachable or responds with error codes, retain the last known balance and usage stats without clearing local caches.

## Do-not-touch zones

- `.git/` — repository history and hooks
- `pubspec.lock` & `extension-react/package-lock.json` — do not modify directly without package manager execution
- `assets/certs/digicert_global_g2.pem` — public DigiCert intermediate CA required for TLS handshake
- Build output directories (`build/`, `extension/`, `node_modules/`, `.dart_tool/`)

## Where to look

- Architecture overview: `docs/ARCHITECTURE.md`
- Product scope & non-goals: `docs/PRODUCT.md`
- Settled decisions: `docs/DECISIONS.md`
- Security rules & threat model: `docs/SECURITY.md`
- API contract: `docs/API.md`
- Database & tables: `docs/DATABASE.md` and `docs/SCHEMA.md`
- Design tokens & spec: `docs/DESIGN.md`
- Brand guidelines & identity: `docs/BRAND.md`
- UI component inventory: `docs/COMPONENTS.md`
- User experience & interaction flows: `docs/UX.md`
- Test strategy: `docs/TESTING.md`
- Android APK & device testing: `docs/ANDROID_DEVICE_TESTING.md`

