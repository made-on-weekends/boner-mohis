import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import 'app_database.dart';

/// DAO for the `accounts` table.
class AccountDao {
  final AppDatabase _appDb;
  AccountDao(this._appDb);

  Future<Database> get _db async => _appDb.database;

  Future<int> insert(Account account) async {
    final db = await _db;
    return db.insert('accounts', account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Account account) async {
    final db = await _db;
    await db.update('accounts', account.toMap(),
        where: 'id = ?', whereArgs: [account.id]);
  }

  Future<void> delete(Account account) async {
    final db = await _db;
    await db.delete('accounts', where: 'id = ?', whereArgs: [account.id]);
  }

  Future<Account?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<List<Account>> getAll() async {
    final db = await _db;
    final rows = await db.query('accounts', orderBy: 'id ASC');
    return rows.map(Account.fromMap).toList();
  }

  /// Polls the accounts table every [pollInterval] and emits whenever the list changes.
  /// Uses a StreamController so the stream cancels cleanly when the subscriber is gone.
  Stream<List<Account>> watchAll({
    Duration pollInterval = const Duration(seconds: 2),
  }) {
    late StreamController<List<Account>> controller;
    Timer? timer;
    String lastSig = '';

    Future<void> check() async {
      try {
        final current = await getAll();
        final sig =
            current.map((a) => '${a.id}:${a.balance}:${a.lastUpdated}').join(',');
        if (sig != lastSig) {
          lastSig = sig;
          if (!controller.isClosed) controller.add(current);
        }
      } catch (_) {}
    }

    controller = StreamController<List<Account>>(
      onListen: () {
        check(); // emit immediately on subscribe
        timer = Timer.periodic(pollInterval, (_) => check());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
        controller.close();
      },
    );

    return controller.stream;
  }
}
