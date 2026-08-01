import 'package:sqflite/sqflite.dart';
import '../models/daily_usage_history.dart';
import 'app_database.dart';

/// DAO for the `daily_usage_history` table.
class DailyUsageDao {
  final AppDatabase _appDb;
  DailyUsageDao(this._appDb);

  Future<Database> get _db async => _appDb.database;

  Future<int> insert(DailyUsageHistory record) async {
    final db = await _db;
    return db.insert('daily_usage_history', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(DailyUsageHistory record) async {
    final db = await _db;
    await db.update('daily_usage_history', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<List<DailyUsageHistory>> getHistoryForAccount(int accountId,
      {int limit = 60}) async {
    final db = await _db;
    final rows = await db.query(
      'daily_usage_history',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date_epoch ASC',
      limit: limit,
    );
    return rows.map(DailyUsageHistory.fromMap).toList();
  }

  Stream<List<DailyUsageHistory>> watchHistoryForAccount(int accountId,
      {Duration pollInterval = const Duration(seconds: 2)}) async* {
    List<DailyUsageHistory> last = [];
    while (true) {
      final current = await getHistoryForAccount(accountId);
      final sig = current.map((h) => '${h.id}:${h.cost}').join(',');
      final lastSig = last.map((h) => '${h.id}:${h.cost}').join(',');
      if (sig != lastSig) {
        last = current;
        yield current;
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<void> deleteHistoryForAccount(int accountId) async {
    final db = await _db;
    await db.delete('daily_usage_history',
        where: 'account_id = ?', whereArgs: [accountId]);
  }

  Future<DailyUsageHistory?> getRecordForDay(
      int accountId, int dayEpoch) async {
    final db = await _db;
    const halfDay = 12 * 60 * 60 * 1000;
    final rows = await db.query(
      'daily_usage_history',
      where: 'account_id = ? AND date_epoch >= ? AND date_epoch < ?',
      whereArgs: [accountId, dayEpoch - halfDay, dayEpoch + halfDay],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyUsageHistory.fromMap(rows.first);
  }
}
