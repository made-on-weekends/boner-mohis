# SCHEMA.md

> Table-by-table reference. High-level strategy lives in `DATABASE.md`.

## Conventions

- **Primary Keys:** Unique string IDs (UUIDs) for Chrome storage and Integer IDs for Android SQLite.
- **Timestamps:** ISO 8601 strings (UTC) for JavaScript, and Long Unix epoch milliseconds for Kotlin Room.
- **Naming:** camelCase for JavaScript objects, snake_case for SQLite table and column names.
- **PII:** Columns containing user account numbers are marked with `[PII]` to require secure handling.

---

## Chrome Extension JSON Schema (chrome.storage.local)

We store accounts and usage history under two root keys: `accounts` and `usage_history`.

### `accounts`

Stored as a list of account objects:

| Key | Type | Notes |
| :--- | :--- | :--- |
| `id` | string (UUID) | Unique account ID |
| `nickname` | string | User-assigned name for the account |
| `distributor` | string | Distributor name identifier |
| `accountNo` | string | Account number `[PII]` |
| `meterNo` | string | Meter serial number `[PII]` |
| `balance` | number | Remaining prepaid balance in local currency |
| `lastUpdated` | string | ISO 8601 timestamp of last reading |
| `currentSlab` | number | Index of active billing slab (0-based) |
| `slabUsage` | number | Amount of energy consumed in the current slab (kWh) |
| `yesterdayUsage` | number | Consumption in local currency yesterday (used for forecasting) |

### `usage_history`

Stored as an object mapping `accountId` to an array of daily log items:

| Key | Type | Notes |
| :--- | :--- | :--- |
| `date` | string | Date in `YYYY-MM-DD` format |
| `consumptionKwh` | number | Energy consumed on this day |
| `cost` | number | Cost of energy consumed on this day in local currency |

---

## Android SQLite Schema (Room Database)

### `accounts` Table

| Column Name | Type | Key | Notes |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto-Increment) | |
| `nickname` | TEXT | Not Null | |
| `distributor` | TEXT | Not Null | |
| `account_no` | TEXT | Not Null | `[PII]` |
| `meter_no` | TEXT | Not Null | `[PII]` |
| `balance` | REAL | Not Null | Remaining balance |
| `last_updated` | INTEGER | Not Null | Unix Epoch MS |
| `current_slab` | INTEGER | Not Null | |
| `slab_usage` | REAL | Not Null | |
| `yesterday_usage`| REAL | Not Null | Consumption in local currency |

### `daily_usage_history` Table

| Column Name | Type | Key | Notes |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto-Increment) | |
| `account_id` | INTEGER | Foreign Key -> `accounts(id)` | ON DELETE CASCADE |
| `date_epoch` | INTEGER | Not Null | Start of day Unix Epoch MS |
| `consumption_kwh`| REAL | Not Null | |
| `cost` | REAL | Not Null | Cost in local currency |

---

## Relationship Overview

```
 ┌───────────────┐          1 : N          ┌─────────────────────┐
 │   accounts    ├────────────────────────►│ daily_usage_history │
 └───────────────┘                         └─────────────────────┘
   id (PK)                                   account_id (FK)
```
