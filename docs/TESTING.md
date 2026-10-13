# TESTING.md

> Test strategy, test suites, and verification commands.

## Stack

- **Flutter Unit & Widget Tests**: `flutter_test` (built-in Flutter test framework)
- **Extension Linter & Verification**: `oxlint` (`^1.71.0`) and Vite build verification

## Commands

```bash
# Flutter Tests
flutter test                          # Run all Flutter unit & widget tests
flutter test test/calculations_helper_test.dart  # Run tariff slab calculation tests
flutter test test/donation_card_test.dart        # Run donation UI widget tests
flutter test test/notification_setup_test.dart   # Run notification scheduler tests

# Extension Checks
npm run lint --prefix extension-react   # Lint extension JavaScript with oxlint
npm run build --prefix extension-react  # Verify production bundle compilation
```

## Test Suites & Coverage

### 1. Tariff Calculation Tests (`test/calculations_helper_test.dart`)
- Validates Bangladesh BERC progressive residential tariff slabs (Slab 1 through Slab 6).
- Tests edge cases for monthly unit transitions (e.g. crossing 75 kWh, 200 kWh, 300 kWh).
- Confirms remaining balance and estimated days remaining calculations.

### 2. Widget & UI Tests (`test/donation_card_test.dart`)
- Confirms donation card renders required maintainer support links.
- Validates UTM query parameters format (`utm_source=boner_mohis`, `ref=boner-mohis-readme`).

### 3. Background Notification Setup (`test/notification_setup_test.dart`)
- Confirms notification channels and notification trigger thresholds for low balance warnings.

## Mocking Philosophy

- **Network Isolation**: Unit and widget tests must never make real network requests to DESCO APIs.
- **DAO In-Memory Fakes**: Repository tests inject in-memory database instances or mock DAOs.

## Physical Device & APK Testing

For end-to-end device testing, APK building, `adb` installation, WorkManager background job triggering, and on-device SQLite inspection, see [ANDROID_DEVICE_TESTING.md](ANDROID_DEVICE_TESTING.md).


## Pre-Release Verification Checklist

Before tagging a release or merging code changes:
- [ ] `flutter analyze` returns 0 errors and 0 warnings.
- [ ] `flutter test` passes all test suites.
- [ ] `npm run lint --prefix extension-react` reports clean output.
- [ ] `npm run build --prefix extension-react` builds without errors.
