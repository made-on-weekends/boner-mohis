import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import '../data/desco_http_client.dart';

const _channelId = 'boner_mohis_low_balance';
const _channelName = 'Low Balance Alerts';
const _channelDesc =
    'Notifies you when a prepaid electricity account balance will deplete within 2 days.';
const _taskName = 'com.bonermohis.balance_check';

/// Notification threshold: alert when fewer than this many days of balance remain.
const double kLowBalanceThresholdDays = 2.0;
const int kTwentyFourHoursMs = 24 * 60 * 60 * 1000;
const int kSixHoursMs = 6 * 60 * 60 * 1000;
const int kOneHourMs = 1 * 60 * 60 * 1000;

final _notifications = FlutterLocalNotificationsPlugin();
bool _notificationsInitialized = false;

/// Initialise the notifications plugin and schedule the hourly background check.
/// Wrapped in try/catch so a WorkManager registration failure never crashes startup.
Future<void> setupNotifications() async {
  try {
    await _ensureNotificationsInitialized();

    await Workmanager().initialize(
      dispatcherCallbackDispatcher,
    );

    // Register 1-hourly task for API retries and 6-hourly low-balance notification checks
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (_) {
    // WorkManager not available (e.g. emulator/desktop) — skip silently.
  }
}

/// Ensures the notifications plugin is initialised (safe to call multiple times).
Future<void> _ensureNotificationsInitialized() async {
  if (_notificationsInitialized) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _notifications.initialize(initSettings);

  final android =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  _notificationsInitialized = true;
}

/// Fire a notification when fresh balance data is successfully synced from DESCO API.
Future<void> sendSyncedBalanceNotification({
  required int id,
  required String nickname,
  required double balance,
}) async {
  await _ensureNotificationsInitialized();

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
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

/// Fire a standard daily balance summary notification for a single account.
Future<void> sendDailyBalanceNotification({
  required int id,
  required String nickname,
  required double daysRemaining,
  required double balance,
}) async {
  await _ensureNotificationsInitialized();

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  const details = NotificationDetails(android: androidDetails);

  final daysText = daysRemaining.isInfinite || daysRemaining.isNaN
      ? '--'
      : '~${daysRemaining.toStringAsFixed(1)}';

  await _notifications.show(
    id + 10000,
    '⚡ Daily Balance Update: $nickname',
    '৳${balance.toStringAsFixed(2)} remaining ($daysText days left).',
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
  await _ensureNotificationsInitialized();

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

/// Check a single account's balance and fire a notification if it is low.
/// Call this from the repository after any balance update (sync / top-up / simulate).
Future<void> checkAndNotifyForAccount({
  required int id,
  required String nickname,
  required double balance,
  required double yesterdayUsage,
}) async {
  if (yesterdayUsage <= 0) return;
  final days = balance / yesterdayUsage;
  if (days <= kLowBalanceThresholdDays) {
    await sendLowBalanceNotification(
      id: id,
      nickname: nickname,
      daysRemaining: days,
      balance: balance,
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

    // Create tracker table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_tracker (
        account_id INTEGER PRIMARY KEY,
        last_api_sync_success_epoch INTEGER NOT NULL DEFAULT 0,
        last_daily_notify_epoch INTEGER NOT NULL DEFAULT 0,
        last_low_balance_notify_epoch INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Re-initialise the plugin inside the background isolate.
    await _ensureNotificationsInitialized();

    final rows = await db.query('accounts');
    final nowMs = DateTime.now().millisecondsSinceEpoch;

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
      int lastDaily = 0;
      int lastLow = 0;
      if (trackerRows.isNotEmpty) {
        lastApiSyncSuccess =
            trackerRows.first['last_api_sync_success_epoch'] as int? ?? 0;
        lastDaily =
            trackerRows.first['last_daily_notify_epoch'] as int? ?? 0;
        lastLow =
            trackerRows.first['last_low_balance_notify_epoch'] as int? ?? 0;
      }

      // Check if DESCO API sync is due (once every 24 hours).
      // If last sync failed, (nowMs - lastApiSyncSuccess) remains >= 24h, retrying hourly.
      bool freshSyncSucceeded = false;
      if (distributor == 'desco' &&
          accountNo.isNotEmpty &&
          meterNo.isNotEmpty &&
          (nowMs - lastApiSyncSuccess) >= kTwentyFourHoursMs) {
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
          // If background network fetch fails, keep lastApiSyncSuccess unchanged
          // so next hourly WorkManager task retries network check.
        }
      }

      // 1. If fresh API balance sync succeeded, push balance notification immediately
      if (freshSyncSucceeded) {
        await sendSyncedBalanceNotification(
          id: id,
          nickname: nickname,
          balance: balance,
        );
        lastDaily = nowMs;
      }

      if (yesterdayUsage <= 0) {
        // Save updated timestamps
        await db.insert(
          'notification_tracker',
          {
            'account_id': id,
            'last_api_sync_success_epoch': lastApiSyncSuccess,
            'last_daily_notify_epoch': lastDaily,
            'last_low_balance_notify_epoch': lastLow,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        continue;
      }

      final days = balance / yesterdayUsage;

      // 2. Low balance notification check every 6 hours (using stored DB balance)
      if (days <= kLowBalanceThresholdDays) {
        if ((nowMs - lastLow) >= kSixHoursMs) {
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
          'last_daily_notify_epoch': lastDaily,
          'last_low_balance_notify_epoch': lastLow,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.close();
  } catch (_) {}
}

Future<Database?> _openDb() async {
  try {
    final dir = await getDatabasesPath();
    // Use p.join so the path is always correct across platforms.
    return await openDatabase(p.join(dir, 'boner_mohis.db'));
  } catch (_) {
    return null;
  }
}



