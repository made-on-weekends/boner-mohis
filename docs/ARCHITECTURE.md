# ARCHITECTURE.md

> Technical structure. How the pieces fit together. Not how to use the project (see AGENTS.md).

## High-level diagram

Both deliverables run 100% locally on user devices, using native local storage engines:

```
Chrome Extension Popup Dashboard
┌────────────────────────┐
│ Popup UI (HTML/CSS/JS) │
└───────────┬────────────┘
            │
            ▼ (JS Adapter Interface)
┌──────────────────────────────────────┐
│ Storage Adapter (chrome.storage)     │ ◄──► [Local Simulator / Provider Mock]
└──────────────────────────────────────┘

Android App Companion
┌──────────────────────────────────────┐
│  Compose UI (Dashboard / Settings)   │
└───────────┬──────────────────────────┘
            │
            ▼ (Repository Pattern)
┌──────────────────────────────────────┐
│  Room Database (SQLite local file)    │ ◄──► [WorkManager Alarm Checker]
└──────────────────────────────────────┘
```

## Layers

### 1. Client Layer (Chrome Extension)
- **Popup UI:** Rendered using vanilla HTML/CSS. Follows premium design principles: glassmorphic design, custom variables, Outfit/Inter fonts, micro-animations, and visual gauge progress meters.
- **Controller/Logic:** `popup.js` controls the UI state, binds event listeners, interacts with local storage, and computes the forecasts.
- **Provider Interface:** A simple adapter interface defining how data is formatted. Contains a `MockProvider` which generates realistic consumption curves, top-up logs, and slab rates.

### 2. Client Layer (Android App)
- **Compose UI:** Kotlin Jetpack Compose interfaces reproducing the dashboard styling and gauge widgets of the extension.
- **WorkManager Service:** Schedules daily checks of the Room Database. Calculates the remaining energy duration for each account and sends local Android Notifications if threshold limits are breached.

### 3. Data Layer
- **Chrome Storage:** Maps account IDs to account settings and history using JSON objects in `chrome.storage.local`.
- **SQLite (Android):** Room database containing tables for `accounts` and `daily_usage_history`.

---

## State and Forecast Lifecycle

1. **Popup Opened / App Launched:**
   - Query local storage for all registered accounts.
   - Fetch the latest usage and balance metrics (either from the simulator adapter or stored state).
   - If yesterday's usage is available, compute forecasting:
     $$\text{Days Remaining} = \frac{\text{Current Balance}}{\text{Yesterday's Usage in Currency}}$$
   - If `Days Remaining` is $\le 2.0$, mark the account as `LOW_BALANCE`.
   - Calculate billing slab percentage:
     $$\text{Slab \%} = \frac{\text{Slab Usage}}{\text{Slab Limit}} \times 100$$
   - Update UI popup dashboard dynamically.

2. **Simulation Tick:**
   - In simulation mode, the user can click "Simulate 24 Hours".
   - The adapter generates a simulated random usage for the day (e.g. 5–15 kWh), subtracts the cost from the balance based on progressive slab rates, and appends the day to history.
   - The dashboard updates immediately.

3. **Android Background Alarm:**
   - Once every 24 hours, `WorkManager` runs in the background.
   - It queries all accounts, does the forecast checks, and emits a notification for any accounts flagged with $\le 2$ days remaining.

---

## Patterns We Use

- **Local First:** All storage is stored directly in device storage, ensuring immediate loads and privacy.
- **Adapter Pattern:** An abstraction layer for energy providers. If scrapers or official APIs are added, they can just implement `getAccountDetails(accountNo)` and return the unified Account object.
- **Simulation Layer:** Emulates consumption and billing rules without needing real-time meter connections.

## Patterns We Avoid

- **External API Dependencies:** No reliance on external databases or cloud sync platforms.
- **Implicit Calculations in UI:** All forecasting logic is separated into an independent calculations utility module (`calculations.js` for extension, `CalculationsHelper` for Kotlin).
