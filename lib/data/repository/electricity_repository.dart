import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/daily_usage_history.dart';
import '../database/account_dao.dart';
import '../database/daily_usage_dao.dart';
import '../calculations_helper.dart';
import '../desco_http_client.dart';
import '../../background/notification_setup.dart';

class ElectricityRepository {
  final AccountDao accountDao;
  final DailyUsageDao dailyUsageDao;

  ElectricityRepository({
    required this.accountDao,
    required this.dailyUsageDao,
  });

  Stream<List<Account>> get allAccounts => accountDao.watchAll();

  Stream<List<DailyUsageHistory>> historyStream(int accountId) =>
      dailyUsageDao.watchHistoryForAccount(accountId);

  Future<int> insertAccount(Account account) => accountDao.insert(account);

  Future<void> deleteAccount(int accountId) async {
    final account = await accountDao.getById(accountId);
    if (account == null) return;
    await dailyUsageDao.deleteHistoryForAccount(accountId);
    await accountDao.delete(account);
  }

  Future<void> topUp(int accountId, double amount) async {
    final account = await accountDao.getById(accountId);
    if (account == null) return;
    final updated = account.copyWith(
      balance: account.balance + amount,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    await accountDao.update(updated);
    // Notify immediately if still low after top-up.
    await checkAndNotifyForAccount(
      id: accountId,
      nickname: updated.nickname,
      balance: updated.balance,
      yesterdayUsage: updated.yesterdayUsage,
    );
  }

  Future<void> resetCycle(int accountId) async {
    final account = await accountDao.getById(accountId);
    if (account == null) return;
    await accountDao.update(
      account.copyWith(
        monthlyKwh: 0.0,
        currentSlab: 0,
        slabUsage: 0.0,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> simulateDay(int accountId, {double? customKwh}) async {
    final account = await accountDao.getById(accountId);
    if (account == null) return;

    final kwhUsed = customKwh ?? (4.0 + Random().nextDouble() * 8.0);

    final oldMonthlyKwh = account.monthlyKwh;
    final newMonthlyKwh = oldMonthlyKwh + kwhUsed;

    final costOfNewTotal = CalculationsHelper.calculateCost(
      newMonthlyKwh,
      provider: account.distributor,
    );
    final costOfOldTotal = CalculationsHelper.calculateCost(
      oldMonthlyKwh,
      provider: account.distributor,
    );
    final dailyCost = max(0.0, costOfNewTotal - costOfOldTotal);

    final newBalance = max(0.0, account.balance - dailyCost);

    final slabStats = CalculationsHelper.getSlabDetails(
      newMonthlyKwh,
      provider: account.distributor,
    );

    await dailyUsageDao.insert(
      DailyUsageHistory(
        accountId: accountId,
        dateEpoch: DateTime.now().millisecondsSinceEpoch,
        consumptionKwh: kwhUsed,
        cost: dailyCost,
      ),
    );

    await accountDao.update(
      account.copyWith(
        balance: newBalance,
        monthlyKwh: newMonthlyKwh,
        yesterdayUsage: dailyCost,
        currentSlab: slabStats.index,
        slabUsage: newMonthlyKwh - slabStats.slabMin,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Notify immediately if the simulated day pushed balance below threshold.
    await checkAndNotifyForAccount(
      id: accountId,
      nickname: account.nickname,
      balance: newBalance,
      yesterdayUsage: dailyCost > 0 ? dailyCost : account.yesterdayUsage,
    );
  }

  Future<String?> syncAccount(int accountId) async {
    final account = await accountDao.getById(accountId);
    if (account == null) return 'Account not found';
    if (account.distributor != 'desco') return null;

    try {
      final client = await createDescoHttpClient();
      try {
        final balanceUri = Uri.parse(
          'https://prepaid.desco.org.bd/api/tkdes/customer/getBalance'
          '?accountNo=${account.accountNo}&meterNo=${account.meterNo}',
        );
        final balanceRes = await client
            .get(balanceUri)
            .timeout(const Duration(seconds: 10));
        final balanceObj = jsonDecode(balanceRes.body) as Map<String, dynamic>;
        if ((balanceObj['code'] as int) != 200) {
          return balanceObj['desc']?.toString() ?? 'DESCO API error';
        }
        final data = balanceObj['data'] as Map<String, dynamic>;
        final liveBalance = (data['balance'] as num).toDouble();

        final sdf = DateFormat('yyyy-MM-dd');
        final dateTo = sdf.format(DateTime.now());
        final dateFrom = sdf.format(
          DateTime.now().subtract(const Duration(days: 15)),
        );

        final consumptionUri = Uri.parse(
          'https://prepaid.desco.org.bd/api/tkdes/customer/getCustomerDailyConsumption'
          '?accountNo=${account.accountNo}&meterNo=${account.meterNo}'
          '&dateFrom=$dateFrom&dateTo=$dateTo',
        );

        double yesterdayCost = account.yesterdayUsage;
        double liveMonthlyKwh = 0.0;

        try {
          final consumptionRes = await client
              .get(consumptionUri)
              .timeout(const Duration(seconds: 10));
          final consumptionObj =
              jsonDecode(consumptionRes.body) as Map<String, dynamic>;

          if ((consumptionObj['code'] as int) == 200) {
            final dataArray = (consumptionObj['data'] as List)
                .cast<Map<String, dynamic>>();
            final list = List<Map<String, dynamic>>.from(dataArray)
              ..sort(
                (a, b) => (a['date'] as String).compareTo(b['date'] as String),
              );

            if (list.isNotEmpty) {
              final latestEntry = list.last;
              final currentMonthStr = (latestEntry['date'] as String).substring(
                0,
                7,
              );
              final lastOfPrevMonth = list.lastWhere(
                (e) => !(e['date'] as String).startsWith(currentMonthStr),
                orElse: () => <String, dynamic>{},
              );
              final baseUnit = lastOfPrevMonth.isNotEmpty
                  ? (lastOfPrevMonth['consumedUnit'] as num).toDouble()
                  : list.firstWhere(
                          (e) =>
                              (e['date'] as String).startsWith(currentMonthStr),
                          orElse: () => latestEntry,
                        )['consumedUnit']
                        is num
                  ? (list.firstWhere(
                              (e) => (e['date'] as String).startsWith(
                                currentMonthStr,
                              ),
                              orElse: () => latestEntry,
                            )['consumedUnit']
                            as num)
                        .toDouble()
                  : (latestEntry['consumedUnit'] as num).toDouble();

              liveMonthlyKwh = max(
                0.0,
                (latestEntry['consumedUnit'] as num).toDouble() - baseUnit,
              );
              liveMonthlyKwh = (liveMonthlyKwh * 1000).roundToDouble() / 1000.0;
            }

            for (int i = 0; i < list.length; i++) {
              final current = list[i];
              final prev = i > 0 ? list[i - 1] : null;

              double dailyKwh = 0.0;
              double dailyCost = 0.0;

              if (prev != null) {
                dailyKwh =
                    (current['consumedUnit'] as num).toDouble() -
                    (prev['consumedUnit'] as num).toDouble();
                final curMonth = (current['date'] as String).split('-')[1];
                final prevMonth = (prev['date'] as String).split('-')[1];
                if (curMonth == prevMonth) {
                  dailyCost = max(
                    0.0,
                    (current['consumedTaka'] as num).toDouble() -
                        (prev['consumedTaka'] as num).toDouble(),
                  );
                } else {
                  dailyCost = (current['consumedTaka'] as num).toDouble();
                }
              }

              if (dailyKwh > 0.0 || dailyCost > 0.0) {
                final dateEpoch = sdf
                    .parse(current['date'] as String)
                    .millisecondsSinceEpoch;
                final existing = await dailyUsageDao.getRecordForDay(
                  accountId,
                  dateEpoch,
                );
                if (existing != null) {
                  await dailyUsageDao.update(
                    existing.copyWith(
                      consumptionKwh: dailyKwh,
                      cost: dailyCost,
                    ),
                  );
                } else {
                  await dailyUsageDao.insert(
                    DailyUsageHistory(
                      accountId: accountId,
                      dateEpoch: dateEpoch,
                      consumptionKwh: dailyKwh,
                      cost: dailyCost,
                    ),
                  );
                }
              }
            }

            if (list.length >= 2) {
              final last = list[list.length - 1];
              final secLast = list[list.length - 2];
              final lastMonth = (last['date'] as String).split('-')[1];
              final secLastMonth = (secLast['date'] as String).split('-')[1];
              if (lastMonth == secLastMonth) {
                yesterdayCost = max(
                  0.0,
                  (last['consumedTaka'] as num).toDouble() -
                      (secLast['consumedTaka'] as num).toDouble(),
                );
              } else {
                yesterdayCost = (last['consumedTaka'] as num).toDouble();
              }
            }
          }
        } catch (_) {}

        final slabStats = CalculationsHelper.getSlabDetails(
          liveMonthlyKwh,
          provider: 'desco',
        );

        await accountDao.update(
          account.copyWith(
            balance: liveBalance,
            monthlyKwh: liveMonthlyKwh,
            yesterdayUsage: yesterdayCost,
            currentSlab: slabStats.index,
            slabUsage: liveMonthlyKwh - slabStats.slabMin,
            lastUpdated: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // Notify immediately after sync if balance is critically low.
        await checkAndNotifyForAccount(
          id: accountId,
          nickname: account.nickname,
          balance: liveBalance,
          yesterdayUsage: yesterdayCost,
        );

        return null;
      } finally {
        client.close();
      }
    } catch (e) {
      return e.toString();
    }
  }
}
