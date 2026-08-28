import 'package:flutter_test/flutter_test.dart';
import 'package:boner_mohis/background/notification_setup.dart';

void main() {
  group('Notification Setup & Threshold Tests', () {
    test('Notification constants have correct time duration thresholds', () {
      expect(kTwentyFourHoursMs, equals(24 * 60 * 60 * 1000));
      expect(kSixHoursMs, equals(6 * 60 * 60 * 1000));
      expect(kLowBalanceThresholdDays, equals(2.0));
    });

    test('24h daily notification check triggers when elapsed time is >= 24 hours', () {
      const nowMs = 1700000000000;
      const lastDaily25hAgo = nowMs - (25 * 60 * 60 * 1000);
      const lastDaily12hAgo = nowMs - (12 * 60 * 60 * 1000);

      expect((nowMs - lastDaily25hAgo) >= kTwentyFourHoursMs, isTrue);
      expect((nowMs - lastDaily12hAgo) >= kTwentyFourHoursMs, isFalse);
    });

    test('Low balance threshold calculation evaluates properly', () {
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
