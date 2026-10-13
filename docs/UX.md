# UX.md

> User flows, interaction patterns, and behavior rules.

## Core Flows

### 1. Account Onboarding / Addition
1. User taps the `+` FAB or header action on `DashboardScreen`.
2. `AddAccountScreen` opens with input fields for:
   - Account Nickname (e.g. "Home", "Basement Meter")
   - DESCO Account Number (8 digits)
   - Meter Number (11–12 digits)
3. User taps "Save & Verify".
4. App performs an initial balance fetch to verify credentials.
5. On success, account is stored in SQLite and user is navigated back to the dashboard with an updated list.
6. On error, inline error message explains whether the meter was not found or network failed, preserving form inputs.

### 2. Daily Monitoring & Refresh
1. User opens the application or pulls down to refresh on `DashboardScreen`.
2. App queries the DESCO API for each registered meter.
3. Balance and remaining days update instantly.
4. If balance is below user threshold (e.g. ৳100), `LowBalanceAlert` renders at the top of the dashboard.

### 3. Consumption History & Slab Deep-Dive
1. User taps an `AccountCard`.
2. `DetailScreen` loads historical usage records from SQLite.
3. Interactive chart displays 30-day consumption in kWh and BDT.
4. User taps "View Tariff Slab Breakdown" to open `ForecastBreakdownSheet`.

---

## Behavior Rules (Always / Never)

**Always:**
- Always show the last-synced timestamp prominently on balance cards.
- Always preserve form input on validation failure.
- Always prompt for confirmation before deleting a meter account.
- Always retain cached data when offline, showing a subtle disconnected banner rather than blank screens.

**Never:**
- Never block UI thread during background network fetches.
- Never use alert dialogs for transient progress — use subtle shimmer loaders or linear progress indicators.
- Never clear historical readings unless the user explicitly removes the account.
- Never show intrusive push alerts unless balance has crossed the critical threshold.

---

## Empty States

- **No Accounts Added**: The dashboard displays a friendly illustration with a clear call-to-action button: "Add Your First Meter".
- **No Consumption History Available**: Detail chart renders a dashed placeholder explaining that daily consumption data is updated by DESCO once daily at midnight.
