# PRODUCT.md

> What we're building, for whom, and what is explicitly NOT in scope.
> This is the canonical scope document. Agents must check here before adding features.

## Product
A local utility consisting of a Chrome Extension and an Android Companion App to track electricity distributor accounts, remaining prepaid balance, current billing slab, and forecast low-balance warnings based on recent daily consumption.

## Target user
Prepaid utility consumers (e.g. residential tenants) who want a unified, beautiful interface to keep track of their prepaid balances and billing slabs so they do not run out of electricity or unexpectedly enter expensive consumption tiers.

## Anti-persona
- Postpaid energy consumers who do not care about daily balances or running out of credit.
- Enterprise energy administrators who require grid-wide IoT telemetry or cloud orchestration.
- Users who expect automatic credit card reloads/top-ups directly from the tracker popup.

## Core value
Providing an immediate, visually elegant warning of when a local prepaid account will run out of balance (within two days) based on the user's actual consumption patterns, without using external servers or databases.

## In scope (current phase)

- **Local Storage Management:** Save, edit, and delete accounts (distributor company, account number, nickname, and parameters) using `chrome.storage.local` (Chrome Extension) and SQLite via Room (Android app).
- **Dashboard Displays:**
  - Remaining balance (in local currency/units).
  - Monthly usage tracker.
  - Current billing slab tier (with a progress gauge indicating how much of the slab is consumed).
  - Forecast of "days remaining" computed from yesterday's consumption.
- **Live API Integration:** Direct integration with official DESCO API (`getBalance` and `getCustomerDailyConsumption`) for live balance and historical consumption tracking.
- **Android Local Alerts:** Local background tasks (`WorkManager`) checking DB status and scheduling local push notifications when accounts are projected to expire in under 2 days.

## Explicitly out of scope

- **Centralized Cloud Database:** No database server. All data remains inside the user's browser storage or mobile storage.
- **Device-to-Device Sync:** No automatic sync. All settings and meter accounts are device-local.
- **Billing Payments Integration:** No payments processing or online top-ups.
- **Other Electricity Providers:** Focused solely on DESCO prepaid meters.

## Phase plan

- **Phase 1: Chrome Extension popup.** Clean UI, local storage, forecasting core, and simulation dashboard.
- **Phase 2: Android companion app.** Local Room database, Compose UI matching extension styles, and background notifications using Alarm/WorkManager.

## Non-goals

- Not a real-time IoT grid monitor (updates are triggered by page load or daily background triggers).
- Not a payment portal.
- Not a replacement for official power company apps (unless they lack forecasting and dashboard capabilities).

## Success criteria

- Chrome extension popup renders in under 150ms.
- 100% local operation with zero network calls for database or state.
- Predictions correctly compute days remaining and trigger low-balance warnings whenever:
  `Balance / YesterdayUsage <= 2.0 days`.
