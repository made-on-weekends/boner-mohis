import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// sqflite database helper.
/// Schema mirrors SCHEMA.md — `accounts` and `daily_usage_history` tables.
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'boner_mohis.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname        TEXT    NOT NULL,
        distributor     TEXT    NOT NULL,
        account_no      TEXT    NOT NULL,
        meter_no        TEXT    NOT NULL,
        balance         REAL    NOT NULL,
        last_updated    INTEGER NOT NULL,
        current_slab    INTEGER NOT NULL,
        slab_usage      REAL    NOT NULL,
        yesterday_usage REAL    NOT NULL,
        monthly_kwh     REAL    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_usage_history (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id       INTEGER NOT NULL,
        date_epoch       INTEGER NOT NULL,
        consumption_kwh  REAL    NOT NULL,
        cost             REAL    NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
