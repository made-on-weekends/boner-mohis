# DATABASE.md

> Database strategy, configuration, and data access patterns.

## Engine & Driver

- **Engine**: SQLite 3
- **Flutter Driver**: `sqflite` (`^2.3.3`)
- **Database File**: `boner_mohis.db` located in the standard application documents directory (via `getDatabasesPath()`).
- **Database Helper**: `AppDatabase` singleton in `lib/data/database/app_database.dart`.

## Browser Extension Storage

The React browser extension uses `chrome.storage.local` rather than SQLite, storing JSON key-value pairs (`accounts`, `settings`, `cachedReadings`).

## Access Patterns & DAO Architecture

Direct SQL queries outside of Data Access Objects are prohibited. All database interactions flow through dedicated DAOs:

- **`AccountDao` (`lib/data/database/account_dao.dart`)**:
  - Handles CRUD for user accounts (`accounts` table).
  - Exposes reactive `Stream<List<Account>>` via stream controllers so UI automatically updates when accounts are inserted or modified.
- **`DailyUsageDao` (`lib/data/database/daily_usage_dao.dart`)**:
  - Handles time-series consumption records (`daily_usage_history` table).
  - Handles upserting daily readings and purging records when an account is deleted.

## Migrations & Schema Evolution

The database version is managed in `AppDatabase._initDb()`:
1. When updating schema, increment `version` in `AppDatabase`.
2. Implement incremental changes inside an `onUpgrade` handler.
3. Never delete existing databases on upgrade; preserve historical consumer readings.

For detailed table-by-table column definitions and types, see [SCHEMA.md](SCHEMA.md).
