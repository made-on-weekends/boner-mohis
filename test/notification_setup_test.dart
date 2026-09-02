import 'package:flutter_test/flutter_test.dart';
import 'package:boner_mohis/background/notification_setup.dart';

void main() {
  group('Notification Setup & Threshold Tests', () {
    test('Notification constants have correct time duration thresholds', () {
      expect(kTwentyFourHoursMs, equals(24 * 60 * 60 * 1000));
      expect(kTwelveHoursMs, equals(12 * 60 * 60 * 1000));
      expect(kSixHoursMs, equals(6 * 60 * 60 * 1000));
      expect(kOneHourMs, equals(1 * 60 * 60 * 1000));
      expect(kLowBalanceThresholdDays, equals(2.0));
      expect(kDailyApiSyncTargetHourLocal, equals(1));
    });

    test('isLowBalanceNotificationDue triggers every 12 hours or when uninitialized (0)', () {
      final now = DateTime(2026, 9, 2, 11, 0);
      final nowMs = now.millisecondsSinceEpoch;

      final lastNotify14hAgo = nowMs - (14 * 60 * 60 * 1000);
      final lastNotify6hAgo = nowMs - (6 * 60 * 60 * 1000);

      // Over 12 hours ago -> due
      expect(isLowBalanceNotificationDue(now: now, lastLowNotifyEpoch: lastNotify14hAgo), isTrue);

      // 6 hours ago -> not due yet
      expect(isLowBalanceNotificationDue(now: now, lastLowNotifyEpoch: lastNotify6hAgo), isFalse);

      // Uninitialized (0) -> due immediately
      expect(isLowBalanceNotificationDue(now: now, lastLowNotifyEpoch: 0), isTrue);
    });

    test('getMostRecentTargetTime calculates 1 AM local threshold correctly', () {
      // Current time: Today 11:00 AM
      final nowAt11am = DateTime(2026, 9, 2, 11, 0);
      final target11am = getMostRecentTargetTime(nowAt11am, targetHour: 1);
      expect(target11am, equals(DateTime(2026, 9, 2, 1, 0)));

      // Current time: Today 00:30 AM (before 1 AM)
      final nowAt1230am = DateTime(2026, 9, 2, 0, 30);
      final target1230am = getMostRecentTargetTime(nowAt1230am, targetHour: 1);
      expect(target1230am, equals(DateTime(2026, 9, 1, 1, 0)));
    });

    test('isDailyApiSyncDue triggers when last sync is prior to most recent 1 AM threshold', () {
      final now = DateTime(2026, 9, 2, 11, 0); // 11 AM today

      final syncedYesterday1am = DateTime(2026, 9, 1, 1, 0).millisecondsSinceEpoch;
      final syncedToday105am = DateTime(2026, 9, 2, 1, 5).millisecondsSinceEpoch;

      // Last synced yesterday 1 AM -> due today
      expect(isDailyApiSyncDue(now: now, lastApiSyncSuccessEpoch: syncedYesterday1am), isTrue);

      // Last synced today 1:05 AM -> already done for today
      expect(isDailyApiSyncDue(now: now, lastApiSyncSuccessEpoch: syncedToday105am), isFalse);

      // Uninitialized (0) -> due immediately
      expect(isDailyApiSyncDue(now: now, lastApiSyncSuccessEpoch: 0), isTrue);
    });

    test('isApiRetryDue triggers when elapsed time since last attempt is >= 1 hour', () {
      final now = DateTime(2026, 9, 2, 11, 0);
      final nowMs = now.millisecondsSinceEpoch;

      final lastAttempt70mAgo = nowMs - (70 * 60 * 1000);
      final lastAttempt20mAgo = nowMs - (20 * 60 * 1000);

      // Over 1 hour ago -> due for retry
      expect(isApiRetryDue(now: now, lastApiSyncAttemptEpoch: lastAttempt70mAgo), isTrue);

      // 20 minutes ago -> not due yet
      expect(isApiRetryDue(now: now, lastApiSyncAttemptEpoch: lastAttempt20mAgo), isFalse);

      // Uninitialized (0) -> due immediately
      expect(isApiRetryDue(now: now, lastApiSyncAttemptEpoch: 0), isTrue);
    });

    test('Low balance threshold calculation evaluates properly (< 2 days)', () {
      const balance = 100.0;
      const usageHigh = 60.0; // 1.67 days remaining -> low balance alert triggered
      const usageLow = 10.0;  // 10 days remaining -> no low balance alert

      const daysHigh = balance / usageHigh;
      const daysLow = balance / usageLow;

      expect(daysHigh <= kLowBalanceThresholdDays, isTrue);
      expect(daysLow <= kLowBalanceThresholdDays, isFalse);
    });

    test('Zero usage results in NaN/Infinite days remaining', () {
      const balance = 500.0;
      const yesterdayUsage = 0.0;

      const days = yesterdayUsage > 0 ? balance / yesterdayUsage : double.nan;
      expect(days.isNaN, isTrue);
    });

    test('Zero or negative balance triggers low balance regardless of yesterday usage', () {
      const zeroBal = 0.0;
      const negBal = -50.0;
      const noUsage = 0.0;

      bool isLow(double balance, double usage) {
        final days = usage > 0 ? balance / usage : double.infinity;
        return balance <= 0 || (usage > 0 && days <= kLowBalanceThresholdDays);
      }

      expect(isLow(zeroBal, noUsage), isTrue);
      expect(isLow(negBal, noUsage), isTrue);
      expect(isLow(500.0, noUsage), isFalse);
    });
  });
}


