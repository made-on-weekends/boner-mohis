import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import '../data/database/app_database.dart';
import '../data/desco_http_client.dart';


const _channelId = 'boner_mohis_low_balance';
const _channelName = 'Low Balance Alerts';
const _channelDesc =
    'Notifies you when a prepaid electricity account balance will deplete within 2 days.';
const _taskName = 'com.bonermohis.balance_check';

/// Notification threshold: alert when fewer than this many days of balance remain.
const double kLowBalanceThresholdDays = 2.0;
const int kTwentyFourHoursMs = 24 * 60 * 60 * 1000;
const int kTwelveHoursMs = 12 * 60 * 60 * 1000;
const int kSixHoursMs = 6 * 60 * 60 * 1000;
const int kOneHourMs = 1 * 60 * 60 * 1000;

/// Target local hour for daily API sync (1 = 1 AM user local time).
const int kDailyApiSyncTargetHourLocal = 1;

/// Calculates the most recent target hour DateTime (e.g. 1 AM local time).
DateTime getMostRecentTargetTime(
  DateTime now, {
  int targetHour = kDailyApiSyncTargetHourLocal,
}) {
  final candidate = DateTime(now.year, now.month, now.day, targetHour, 0, 0);
  if (now.isBefore(candidate)) {
    return candidate.subtract(const Duration(days: 1));
  }
  return candidate;
}

/// Checks if daily API sync at 1 AM local time is due.
bool isDailyApiSyncDue({
  required DateTime now,
  required int lastApiSyncSuccessEpoch,
  int targetLocalHour = kDailyApiSyncTargetHourLocal,
}) {
  if (lastApiSyncSuccessEpoch == 0) return true;
  final targetTime = getMostRecentTargetTime(now, targetHour: targetLocalHour);
  return lastApiSyncSuccessEpoch < targetTime.millisecondsSinceEpoch;
}

/// Checks if API sync retry is due (retries every 1 hour after a failed API call).
bool isApiRetryDue({
  required DateTime now,
  required int lastApiSyncAttemptEpoch,
}) {
  if (lastApiSyncAttemptEpoch == 0) return true;
  final nowMs = now.millisecondsSinceEpoch;
  return (nowMs - lastApiSyncAttemptEpoch) >= kOneHourMs;
}

/// Checks if low balance notification is due (every 12 hours).
bool isLowBalanceNotificationDue({
  required DateTime now,
  required int lastLowNotifyEpoch,
}) {
  if (lastLowNotifyEpoch == 0) return true;
  final nowMs = now.millisecondsSinceEpoch;
  return (nowMs - lastLowNotifyEpoch) >= kTwelveHoursMs;
}

final _notifications = FlutterLocalNotificationsPlugin();
bool _notificationsInitialized = false;

/// Initialise the notifications plugin and schedule the background check.
/// Wrapped in try/catch so a WorkManager registration failure never crashes startup.
Future<void> setupNotifications() async {
  try {
    await _ensureNotificationsInitialized(requestPermission: true);

    await Workmanager().initialize(
      dispatcherCallbackDispatcher,
    );

    // Register periodic task for 1 AM daily API sync, hourly failure retries, and 12h low-balance checks
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (_) {
    // WorkManager not available (e.g. emulator/desktop) — skip silently.
  }
}

/// Ensures the notifications plugin is initialised (safe to call in UI or background isolate).
Future<void> _ensureNotificationsInitialized({bool requestPermission = true}) async {
  if (_notificationsInitialized) return;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  try {
    await _notifications.initialize(initSettings);
  } catch (_) {}

  final android =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (requestPermission) {
    try {
      await android?.requestNotificationsPermission();
    } catch (_) {
      // Background isolate has no Activity context for permission dialogs.
    }
  }

  try {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await android?.createNotificationChannel(channel);
  } catch (_) {}

  _notificationsInitialized = true;
}

/// Fire a notification when fresh balance data is successfully synced from DESCO API.
Future<void> sendSyncedBalanceNotification({
  required int id,
  required String nickname,
  required double balance,
}) async {
  await _ensureNotificationsInitialized(requestPermission: false);

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const details = NotificationDetails(android: androidDetails);

  await _notifications.show(
    id + 20000,
    '⚡ Balance Synced: $nickname',
    'Updated prepaid balance: ৳${balance.toStringAsFixed(2)}',
    details,
  );
}

/// Fire an urgent low-balance push notification for a single account.
Future<void> sendLowBalanceNotification({
  required int id,
  required String nickname,
  required double daysRemaining,
  required double balance,
}) async {
  await _ensureNotificationsInitialized(requestPermission: false);

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const details = NotificationDetails(android: androidDetails);

  final body = daysRemaining <= 1.0
      ? '৳${balance.toStringAsFixed(2)} remaining — less than 1 day left!'
      : '৳${balance.toStringAsFixed(2)} remaining — ~${daysRemaining.toStringAsFixed(1)} days left.';

  await _notifications.show(
    id,
    '⚡ Low balance warning: $nickname',
    body,
    details,
  );
}

/// Check a single account's balance and fire low-balance notification if due.
/// Call this from the repository after any balance update (sync / top-up / simulate).
Future<void> checkAndNotifyForAccount({
  required int id,
  required String nickname,
  required double balance,
  required double yesterdayUsage,
}) async {
  final days = yesterdayUsage > 0 ? balance / yesterdayUsage : double.infinity;
  final now = DateTime.now();
  final nowMs = now.millisecondsSinceEpoch;
  final db = await _openDb();
  int lastApiSyncSuccess = 0;
  int lastApiSyncAttempt = 0;
  int lastDaily = 0;
  int lastLow = 0;

  if (db != null) {
    final trackerRows = await db.query(
      'notification_tracker',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    if (trackerRows.isNotEmpty) {
      lastApiSyncSuccess =
          trackerRows.first['last_api_sync_success_epoch'] as int? ?? 0;
      lastApiSyncAttempt =
          trackerRows.first['last_api_sync_attempt_epoch'] as int? ?? 0;
      lastDaily =
          trackerRows.first['last_daily_notify_epoch'] as int? ?? 0;
      lastLow =
          trackerRows.first['last_low_balance_notify_epoch'] as int? ?? 0;
    }
  }

  bool trackerUpdated = false;

  // Urgent low balance notification check (every 12 hours)
  if (balance <= 0 || (yesterdayUsage > 0 && days <= kLowBalanceThresholdDays)) {
    if (isLowBalanceNotificationDue(now: now, lastLowNotifyEpoch: lastLow)) {
      await sendLowBalanceNotification(
        id: id,
        nickname: nickname,
        daysRemaining: days,
        balance: balance,
      );
      lastLow = nowMs;
      trackerUpdated = true;
    }
  }

  if (db != null && trackerUpdated) {
    await db.insert(
      'notification_tracker',
      {
        'account_id': id,
        'last_api_sync_success_epoch': lastApiSyncSuccess,
        'last_api_sync_attempt_epoch': lastApiSyncAttempt,
        'last_daily_notify_epoch': lastDaily,
        'last_low_balance_notify_epoch': lastLow,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// ---------------------------------------------------------------------------
// Background task (Workmanager) — runs even when the app is closed.
// ---------------------------------------------------------------------------

/// WorkManager entry-point. Must be a top-level function.
/// IMPORTANT: WidgetsFlutterBinding.ensureInitialized() is REQUIRED here —
/// the background isolate has no Flutter binding yet and will crash without it.
@pragma('vm:entry-point')
void dispatcherCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == _taskName) {
        await _runBalanceCheck();
      }
    } catch (_) {
      // Never let the task throw — returning true tells WorkManager success.
    }
    return true;
  });
}

Future<void> _runBalanceCheck() async {
  try {
    final db = await _openDb();
    if (db == null) return;

    // Re-initialise the plugin inside the background isolate without requesting Activity permission dialogs.
    await _ensureNotificationsInitialized(requestPermission: false);

    final rows = await db.query('accounts');
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    for (final row in rows) {
      final id = row['id'] as int;
      final nickname = row['nickname'] as String;
      final distributor = row['distributor'] as String;
      final accountNo = row['account_no'] as String;
      final meterNo = row['meter_no'] as String;

      double balance = (row['balance'] as num).toDouble();
      double yesterdayUsage = (row['yesterday_usage'] as num).toDouble();

      // Read last notification & sync timestamps
      final trackerRows = await db.query(
        'notification_tracker',
        where: 'account_id = ?',
        whereArgs: [id],
      );
      int lastApiSyncSuccess = 0;
      int lastApiSyncAttempt = 0;
      int lastDaily = 0;
      int lastLow = 0;
      if (trackerRows.isNotEmpty) {
        lastApiSyncSuccess =
            trackerRows.first['last_api_sync_success_epoch'] as int? ?? 0;
        lastApiSyncAttempt =
            trackerRows.first['last_api_sync_attempt_epoch'] as int? ?? 0;
        lastDaily =
            trackerRows.first['last_daily_notify_epoch'] as int? ?? 0;
        lastLow =
            trackerRows.first['last_low_balance_notify_epoch'] as int? ?? 0;
      }

      // Check if daily 1 AM DESCO API sync is due AND retry interval (1 hour on failure) has passed
      bool freshSyncSucceeded = false;
      final apiSyncDue = isDailyApiSyncDue(
        now: now,
        lastApiSyncSuccessEpoch: lastApiSyncSuccess,
      );
      final apiRetryDue = isApiRetryDue(
        now: now,
        lastApiSyncAttemptEpoch: lastApiSyncAttempt,
      );

      if (distributor == 'desco' &&
          accountNo.isNotEmpty &&
          meterNo.isNotEmpty &&
          apiSyncDue &&
          apiRetryDue) {
        lastApiSyncAttempt = nowMs; // Record attempt timestamp
        try {
          http.Client client;
          try {
            client = await createDescoHttpClient();
          } catch (_) {
            client = http.Client();
          }

          try {
            final balanceUri = Uri.parse(
              'https://prepaid.desco.org.bd/api/tkdes/customer/getBalance'
              '?accountNo=$accountNo&meterNo=$meterNo',
            );
            final res = await client
                .get(balanceUri)
                .timeout(const Duration(seconds: 10));
            if (res.statusCode == 200) {
              final obj = jsonDecode(res.body) as Map<String, dynamic>;
              if ((obj['code'] as int?) == 200 && obj['data'] is Map) {
                final data = obj['data'] as Map<String, dynamic>;
                if (data['balance'] is num) {
                  balance = (data['balance'] as num).toDouble();
                  lastApiSyncSuccess = nowMs;
                  freshSyncSucceeded = true;
                  await db.update(
                    'accounts',
                    {
                      'balance': balance,
                      'last_updated': nowMs,
                    },
                    where: 'id = ?',
                    whereArgs: [id],
                  );
                }
              }
            }
          } finally {
            client.close();
          }
        } catch (_) {
          // If background network fetch fails, lastApiSyncAttempt recorded nowMs,
          // so next hourly WorkManager run will retry in 1 hour until successful.
        }
      }

      final days = yesterdayUsage > 0 ? balance / yesterdayUsage : double.nan;

      // 1. Notify on fresh 1 AM daily sync success
      if (freshSyncSucceeded) {
        await sendSyncedBalanceNotification(
          id: id,
          nickname: nickname,
          balance: balance,
        );
        lastDaily = nowMs;
      }

      // 2. Low balance notification check every 12 hours
      if (balance <= 0 || (yesterdayUsage > 0 && days <= kLowBalanceThresholdDays)) {
        if (isLowBalanceNotificationDue(now: now, lastLowNotifyEpoch: lastLow)) {
          await sendLowBalanceNotification(
            id: id,
            nickname: nickname,
            daysRemaining: days,
            balance: balance,
          );
          lastLow = nowMs;
        }
      }

      // Save updated tracker timestamps
      await db.insert(
        'notification_tracker',
        {
          'account_id': id,
          'last_api_sync_success_epoch': lastApiSyncSuccess,
          'last_api_sync_attempt_epoch': lastApiSyncAttempt,
          'last_daily_notify_epoch': lastDaily,
          'last_low_balance_notify_epoch': lastLow,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  } catch (_) {}
}

Future<Database?> _openDb() async {
  try {
    final db = await AppDatabase().database;
    await _ensureTrackerTableSchema(db);
    return db;
  } catch (_) {
    try {
      final dir = await getDatabasesPath();
      final db = await openDatabase(p.join(dir, 'boner_mohis.db'));
      await _ensureTrackerTableSchema(db);
      return db;
    } catch (_) {
      return null;
    }
  }
}

Future<void> _ensureTrackerTableSchema(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS notification_tracker (
      account_id INTEGER PRIMARY KEY,
      last_api_sync_success_epoch INTEGER NOT NULL DEFAULT 0,
      last_api_sync_attempt_epoch INTEGER NOT NULL DEFAULT 0,
      last_daily_notify_epoch INTEGER NOT NULL DEFAULT 0,
      last_low_balance_notify_epoch INTEGER NOT NULL DEFAULT 0
    )
  ''');
  try {
    await db.execute(
      'ALTER TABLE notification_tracker ADD COLUMN last_api_sync_attempt_epoch INTEGER NOT NULL DEFAULT 0',
    );
  } catch (_) {
    // Column already exists
  }
}





