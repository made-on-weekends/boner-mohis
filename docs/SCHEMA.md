# SCHEMA.md

> Table-by-table reference for the SQLite database (`boner_mohis.db`).

## Tables

### 1. `accounts`

Stores monitored DESCO customer prepaid accounts and their latest cached metrics.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Internal local surrogate key |
| `nickname` | `TEXT` | `NOT NULL` | User-defined label (e.g., "Home", "Office") |
| `distributor` | `TEXT` | `NOT NULL` | Utility provider identifier (`desco`) |
| `account_no` | `TEXT` | `NOT NULL` | DESCO consumer account number |
| `meter_no` | `TEXT` | `NOT NULL` | Physical meter serial number |
| `balance` | `REAL` | `NOT NULL` | Current prepaid balance in BDT (৳) |
| `last_updated` | `INTEGER` | `NOT NULL` | Unix timestamp (ms) of the last successful balance sync |
| `current_slab` | `INTEGER` | `NOT NULL` | Current progressive BERC tariff slab (1 to 6) |
| `slab_usage` | `REAL` | `NOT NULL` | kWh consumed within the current tariff slab |
| `yesterday_usage` | `REAL` | `NOT NULL` | Total cost incurred on the previous calendar day (৳) |
| `monthly_kwh` | `REAL` | `NOT NULL` | Cumulative units consumed in the active billing month (kWh) |

---

### 2. `daily_usage_history`

Stores daily historical consumption logs for generating charts and calculating run-rates.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Internal record identifier |
| `account_id` | `INTEGER` | `NOT NULL` | Foreign key referencing `accounts(id)` |
| `date` | `TEXT` | `NOT NULL` | Reading date formatted as `yyyy-MM-dd` |
| `kwh` | `REAL` | `NOT NULL` | Electricity consumed on that date (kWh) |
| `cost` | `REAL` | `NOT NULL` | Electricity cost incurred on that date (৳) |

---

## Indices & Constraints

- `daily_usage_history(account_id, date)`: Unique compound constraint prevents duplicate daily readings per account.
- Cascading Deletes: When an account is removed via `ElectricityRepository.deleteAccount()`, associated rows in `daily_usage_history` are explicitly removed.
