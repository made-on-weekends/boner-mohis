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
        double numToDouble(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          return double.tryParse(val.toString()) ?? 0.0;
        }

        final liveBalance = numToDouble(data['balance']);

        final sdf = DateFormat('yyyy-MM-dd');
        final dateTo = sdf.format(DateTime.now());
        final dateFrom = sdf.format(
          DateTime.now().subtract(const Duration(days: 35)),
        );

        final consumptionUri = Uri.parse(
          'https://prepaid.desco.org.bd/api/tkdes/customer/getCustomerDailyConsumption'
          '?accountNo=${account.accountNo}&meterNo=${account.meterNo}'
          '&dateFrom=$dateFrom&dateTo=$dateTo',
        );

        double yesterdayCost = account.yesterdayUsage;
        double liveMonthlyKwh = 0.0;
        double baseUnit = 0.0;

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
              baseUnit = lastOfPrevMonth.isNotEmpty
                  ? numToDouble(lastOfPrevMonth['consumedUnit'])
                  : numToDouble(
                      list.firstWhere(
                        (e) => (e['date'] as String).startsWith(currentMonthStr),
                        orElse: () => latestEntry,
                      )['consumedUnit'],
                    );

              liveMonthlyKwh = max(
                0.0,
                numToDouble(latestEntry['consumedUnit']) - baseUnit,
              );
              liveMonthlyKwh = (liveMonthlyKwh * 1000).roundToDouble() / 1000.0;
            }

            for (int i = 0; i < list.length; i++) {
              final current = list[i];
              final prev = i > 0 ? list[i - 1] : null;

              double dailyKwh = 0.0;
              double dailyCost = 0.0;

              if (prev != null) {
                final curUnit = numToDouble(current['consumedUnit']);
                final prevUnit = numToDouble(prev['consumedUnit']);
                final curTaka = numToDouble(current['consumedTaka']);
                final prevTaka = numToDouble(prev['consumedTaka']);

                dailyKwh = max(0.0, curUnit - prevUnit);
                final curMonth = (current['date'] as String).split('-')[1];
                final prevMonth = (prev['date'] as String).split('-')[1];
                if (curMonth == prevMonth) {
                  dailyCost = max(0.0, curTaka - prevTaka);
                } else {
                  dailyCost = curTaka;
                }

                // Fallback: If odometer reading did not update (dailyKwh is 0) but cost was billed,
                // estimate daily kWh using active slab rate.
                if (dailyKwh == 0.0 && dailyCost > 5.0) {
                  final curUnitVal = numToDouble(current['consumedUnit']);
                  final monthlyKwhAtDate = curUnitVal > 0.0 ? curUnitVal - baseUnit : liveMonthlyKwh;
                  final slabDetails = CalculationsHelper.getSlabDetails(
                    max(0.0, monthlyKwhAtDate),
                    provider: 'desco',
                  );
                  final rate = slabDetails.rate > 0 ? slabDetails.rate : 6.18;
                  dailyKwh = (dailyCost / rate * 1000).roundToDouble() / 1000.0;
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
                  numToDouble(last['consumedTaka']) -
                      numToDouble(secLast['consumedTaka']),
                );
              } else {
                yesterdayCost = numToDouble(last['consumedTaka']);
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

  Future<void> syncAllAccounts() async {
    final accounts = await accountDao.getAll();
    for (final account in accounts) {
      if (account.id != null && account.distributor == 'desco') {
        await syncAccount(account.id!);
      }
    }
  }
}

