# ARCHITECTURE.md

> Technical structure. How the pieces fit together. Not how to use the project (see AGENTS.md).

## High-level diagram

```
┌────────────────────────────────────────────────────────┐
│                   Boner Mohis System                   │
└────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────┐      ┌───────────────────────────────┐
  │   Android Mobile App (Flutter)  │      │   Browser Extension (React)   │
  │                                 │      │                               │
  │   ┌─────────────────────────┐   │      │   ┌───────────────────────┐   │
  │   │  UI / Screens & Widgets │   │      │   │  React 19 Popup UI    │   │
  │   │  (Filament Theme System)│   │      │   │  (Vite Build Output)  │   │
  │   └────────────┬────────────┘   │      │   └───────────┬───────────┘   │
  │                │                │      │               │               │
  │   ┌────────────▼────────────┐   │      │   ┌───────────▼───────────┐   │
  │   │  Riverpod State & Notif │   │      │   │  chrome.storage.local │   │
  │   └────────────┬────────────┘   │      │   └───────────┬───────────┘   │
  │                │                │      │               │               │
  │   ┌────────────▼────────────┐   │      │   ┌───────────▼───────────┐   │
  │   │  sqflite (SQLite DB)    │   │      │   │  Extension Service    │   │
  │   │  boner_mohis.db         │   │      │   │  Worker (background)  │   │
  │   └────────────┬────────────┘   │      │   └───────────┬───────────┘   │
  │                │                │      │               │               │
  │   ┌────────────▼────────────┐   │      │               │               │
  │   │  Workmanager Background │   │      │               │               │
  │   └────────────┬────────────┘   │      │               │               │
  │                │                │      │               │               │
  │   ┌────────────▼────────────┐   │      │               │               │
  │   │  Custom TLS Context     │   │      │               │               │
  │   │  (DigiCert CA Pinning)  │   │      │               │               │
  │   └────────────┬────────────┘   │      │               │               │
  └────────────────┼────────────────┘      └───────────────┼───────────────┘
                   │                                       │
                   │ HTTPS GET                             │ HTTPS GET
                   │ (TLS pinned)                          │ (Browser AIA)
                   ▼                                       ▼
       ┌───────────────────────────────────────────────────────┐
       │             DESCO Customer API Endpoints              │
       │           https://prepaid.desco.org.bd/api            │
       └───────────────────────────────────────────────────────┘
```

## Layers

### 1. Mobile Client (Flutter / Android)
- **UI & Presentation (`lib/ui/`)**: Built with Material 3 base customized with the `FilamentTheme` palette. Displays balance cards, tariff slab progress indicators, daily consumption charts, and account addition sheets.
- **State Management (`lib/providers/`)**: `flutter_riverpod` provides reactive state for accounts, selected meter, sync states, and calculations.
- **Data & Storage (`lib/data/`)**: SQLite database (`boner_mohis.db`) managed via `AppDatabase`, with DAOs for `AccountDao` and `DailyUsageDao`.
- **Background Sync (`lib/background/`)**: Android `Workmanager` periodically fetches updated balances in the background and schedules alerts via `flutter_local_notifications`.

### 2. Browser Extension (`extension-react/`)
- **Presentation**: Single-page React 19 popup compiled via Vite 8 into vanilla bundle files under `extension/`.
- **Styling**: Vanilla CSS (`index.css`) consuming brand custom properties from `theme.css`.
- **Storage**: `chrome.storage.local` storing account credentials and cached balance metrics.
- **Background Worker**: `background.js` handles alarm scheduling, periodic polling, and toolbar icon color updates.

### 3. External API Integration
- Direct communication with DESCO Prepaid Web Service:
  - `getBalance`: Real-time account balance, current month consumed units, and meter timestamp.
  - `getCustomerDailyConsumption`: 35-day sliding window of daily kWh consumption.
- **TLS Handshake Mitigation**: Android devices fail TLS handshakes because DESCO servers omit intermediate certificates. `desco_http_client.dart` explicitly trusts `assets/certs/digicert_global_g2.pem` in a dedicated `SecurityContext`.

## Request Lifecycle

1. **User Action / Background Trigger**: User opens app or Workmanager background job fires.
2. **Account Retrieval**: Active accounts are read from `AccountDao` (or `chrome.storage.local`).
3. **HTTP Fetch**: `ElectricityRepository` invokes `createDescoHttpClient()`.
4. **API Call**: GET request dispatched to `prepaid.desco.org.bd/api/tkdes/customer/getBalance`.
5. **JSON Parse & Validation**: Response status code verified (`200`). Payload parsed and cast safely.
6. **Slab & Daily Consumption Calculation**: `CalculationsHelper` evaluates cumulative monthly units against BERC tariff slabs.
7. **Database Persistence**: Updated balance, timestamp, and consumption rows saved to SQLite.
8. **UI State & Notification**: Stream controllers notify Riverpod providers; if balance falls below threshold, local notification triggers.

## Patterns we use

- **Repository & DAO Pattern**: All SQLite access is encapsulated in DAOs (`AccountDao`, `DailyUsageDao`), consumed exclusively by `ElectricityRepository`.
- **Custom SecurityContext**: Scoped certificate trust strictly for DESCO API clients without modifying global VM security settings.
- **Immutable State Objects**: Models (`Account`, `DailyUsageHistory`, `SlabCalculation`) are immutable data structures.
- **Local-First Architecture**: No cloud dependencies or telemetry; 100% functional offline with cached data.

## Patterns we avoid

- **Global HTTP Overrides**: Never use `HttpOverrides.global` with `badCertificateCallback = true`. Insecure TLS bypasses are prohibited.
- **Direct Database Queries from UI**: Widgets never query `sqflite` directly; all data flows through Riverpod providers.
- **Shared Secrets in Client**: No private API keys or hardcoded user credentials.
