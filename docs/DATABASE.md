# DATABASE.md

> High-level database strategy. Engine, storage policies, migrations.
> Table-by-table reference lives in `SCHEMA.md`.

## Engine

1. **Chrome Extension:** `chrome.storage.local` (persistent key-value JSON storage provided by the browser).
2. **Android App:** SQLite local file database managed via Android's Room library.

## Connection

- **Chrome Extension:**
  All access to data is mediated via a helper class in `storage.js` which provides async wrappers for getting/setting accounts and usage history.
  ```javascript
  import { db } from './storage.js';
  const accounts = await db.getAccounts();
  ```
- **Android App:**
  Access is mediated via Room DAOs.
  ```kotlin
  val database = Room.databaseBuilder(context, AppDatabase::class.java, "boner_mohis.db").build()
  ```

## Do / Don't

**Do:**
- Always write type-safe data schemas (validate JSON items at the storage boundary).
- Keep historical usage data compact: limit historical logs to 60 days of daily usage to avoid storage inflation.
- Always use Room transactions in Android when writing to multiple tables.
- Use explicit keys for storage partitions (`accounts`, `simulation_settings`).

**Don't:**
- Don't store plain text credentials (passwords, tokens) in local storage without checking `SECURITY.md` guidelines.
- Don't block the UI thread: Chrome Extension reads must be asynchronous, and Android Room database queries must run on background dispatchers (`Dispatchers.IO`).
- Don't store redundant forecast data; calculate fields like `daysRemaining` and `slabPercentage` on the fly from the raw data.

## Multi-tenancy / Accounts Strategy
The app is single-user but supports tracking multiple utility accounts. Accounts are identified by a unique `id` (e.g., UUID or auto-incremented primary key) and have a reference to the distributor company.

## Migrations
- **Chrome Extension:** Incremental JSON migration logic implemented manually inside `storage.js` based on a stored `schema_version` integer.
- **Android App:** Standard Room database migrations. If schema changes occur, write a migration script or use automatic migrations during early development.
