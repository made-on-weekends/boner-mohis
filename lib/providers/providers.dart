import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/account_dao.dart';
import '../data/database/daily_usage_dao.dart';
import '../data/repository/electricity_repository.dart';
import '../data/models/account.dart';
import '../data/models/daily_usage_history.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final accountDaoProvider = Provider<AccountDao>((ref) {
  return AccountDao(ref.watch(appDatabaseProvider));
});

final dailyUsageDaoProvider = Provider<DailyUsageDao>((ref) {
  return DailyUsageDao(ref.watch(appDatabaseProvider));
});

final repositoryProvider = Provider<ElectricityRepository>((ref) {
  return ElectricityRepository(
    accountDao: ref.watch(accountDaoProvider),
    dailyUsageDao: ref.watch(dailyUsageDaoProvider),
  );
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(repositoryProvider).allAccounts;
});

final selectedAccountIdProvider = StateProvider<int?>((ref) => null);

final selectedAccountProvider = Provider<Account?>((ref) {
  final id = ref.watch(selectedAccountIdProvider);
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
  if (id == null) return null;
  try {
    return accounts.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

final historyStreamProvider =
    StreamProvider.family<List<DailyUsageHistory>, int>((ref, accountId) {
  return ref.watch(repositoryProvider).historyStream(accountId);
});

final syncLoadingProvider = StateProvider<bool>((ref) => false);
final syncErrorProvider = StateProvider<String?>((ref) => null);
final currentScreenProvider = StateProvider<String>((ref) => 'dashboard');
