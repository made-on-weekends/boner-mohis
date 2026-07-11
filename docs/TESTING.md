# TESTING.md

> Test strategy and commands.

## Stack

- **Android Companion App:**
  - Unit testing: JUnit 4 (Kotlin tests verifying progressive slab calculations, cost logic, and forecasts).
- **Chrome Extension:**
  - Standard manual validation and interactive simulator checks since calculations mirror the verified Kotlin helper logic.

## Commands

### Android Unit Tests
```bash
# Run all unit tests for the Android project
./gradlew test
```

## File layout

- Kotlin unit tests: `android/app/src/test/java/com/example/bonermohis/data/CalculationsHelperTest.kt`

## What to test

**Do test:**
- Core business calculations (progressive billing costs, active slab allocations, days remaining forecast).
- Zero-usage and negative balance bounds to ensure forecasting displays `--` or handles low balances gracefully.
- Slab boundary conditions (e.g. exactly 50 kWh Lifeline tier threshold, First Step billing starts at 0 kWh if usage > 50 kWh).

**Don't test:**
- Third-party chart rendering libraries or the Android Jetpack Compose rendering framework itself.
- Simple database getter/setter DAOs.

## Conventions

- Test names must clearly describe the behavior under test (e.g. `testCalculateCost_exceedsLifeline_desco`).
- Keep test data scenarios simple and verify exact monetary values against the tariff rules defined in `docs/TARIFF.md`.
