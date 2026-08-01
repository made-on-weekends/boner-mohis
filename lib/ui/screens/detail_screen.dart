import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/calculations_helper.dart';
import '../../providers/providers.dart';
import '../theme/filament_theme.dart';
import '../widgets/charge_bar.dart';
import '../widgets/low_balance_alert.dart';
import '../widgets/stat_card.dart';
import '../widgets/usage_chart.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _syncRotation;
  final _topUpController = TextEditingController();
  bool _showDismissedAlert = false;

  @override
  void initState() {
    super.initState();
    _syncRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = ref.read(selectedAccountProvider);
      if (account?.distributor == 'desco') {
        _triggerSync();
      }
    });
  }

  @override
  void dispose() {
    _syncRotation.dispose();
    _topUpController.dispose();
    super.dispose();
  }

  Future<void> _triggerSync() async {
    if (!mounted) return;
    ref.read(syncLoadingProvider.notifier).state = true;
    ref.read(syncErrorProvider.notifier).state = null;
    _syncRotation.repeat();
    final id = ref.read(selectedAccountIdProvider);
    if (id == null) return;
    final error = await ref.read(repositoryProvider).syncAccount(id);
    if (!mounted) return;
    _syncRotation.stop();
    _syncRotation.reset();
    ref.read(syncLoadingProvider.notifier).state = false;
    if (error != null) {
      ref.read(syncErrorProvider.notifier).state = error;
    }
  }

  Future<void> _simulateDay() async {
    final id = ref.read(selectedAccountIdProvider);
    if (id == null) return;
    await ref.read(repositoryProvider).simulateDay(id);
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_topUpController.text);
    if (amount == null || amount <= 0) return;
    final id = ref.read(selectedAccountIdProvider);
    if (id == null) return;
    await ref.read(repositoryProvider).topUp(id, amount);
    _topUpController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete account?',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500)),
        content: Text(
          'Are you sure you want to delete this account? This will remove all usage history.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: FilamentColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final id = ref.read(selectedAccountIdProvider);
      if (id != null) await ref.read(repositoryProvider).deleteAccount(id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedAccountProvider);
    final syncLoading = ref.watch(syncLoadingProvider);
    final syncError = ref.watch(syncErrorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (account == null) {
      // Account was deleted or provider returned null — pop back automatically.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final historyAsync =
        ref.watch(historyStreamProvider(account.id!));
    final history = historyAsync.valueOrNull ?? [];

    final daysRemaining = CalculationsHelper.calculateDaysRemaining(
        account.balance, account.yesterdayUsage);
    final isLowBalance =
        daysRemaining != double.infinity && daysRemaining <= 2.0;
    final slabDetails = CalculationsHelper.getSlabDetails(account.monthlyKwh,
        provider: account.distributor);

    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    final isSimulation = account.distributor != 'desco';
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(account.lastUpdated));

    return Scaffold(
      appBar: AppBar(
        title: Text(account.nickname),
        actions: [
          if (!isSimulation)
            RotationTransition(
              turns: _syncRotation,
              child: IconButton(
                icon: const Icon(Icons.sync),
                color: syncLoading
                    ? FilamentColors.emberOrange
                    : textMuted,
                tooltip: 'Sync live data',
                onPressed: syncLoading ? null : _triggerSync,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: FilamentColors.danger,
            tooltip: 'Delete account',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (syncError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FilamentColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: FilamentColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: FilamentColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sync failed: $syncError',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: FilamentColors.danger)),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(syncErrorProvider.notifier).state = null,
                      child: const Icon(Icons.close,
                          size: 14, color: FilamentColors.danger),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (isLowBalance && !_showDismissedAlert) ...[
              LowBalanceAlert(
                daysRemaining: daysRemaining,
                balance: account.balance,
                onDismiss: () =>
                    setState(() => _showDismissedAlert = true),
              ),
              const SizedBox(height: 16),
            ],

            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining Balance',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('৳',
                          style: GoogleFonts.dmMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: FilamentColors.textSecondary,
                          )),
                      const SizedBox(width: 4),
                      Text(
                        account.balance.toStringAsFixed(2),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 52,
                          fontWeight: FontWeight.w500,
                          color: isLowBalance
                              ? FilamentColors.danger
                              : textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Updated $dateStr',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                StatCard(
                  label: 'Days Remaining',
                  value: daysRemaining == double.infinity
                      ? '--'
                      : daysRemaining.toStringAsFixed(1),
                  unit: daysRemaining == double.infinity ? null : 'days',
                  icon: Icons.schedule_outlined,
                  valueColor: isLowBalance
                      ? FilamentColors.danger
                      : FilamentColors.success,
                  highlight: isLowBalance,
                ),
                StatCard(
                  label: 'Yesterday Usage',
                  value: account.yesterdayUsage > 0
                      ? '৳${account.yesterdayUsage.toStringAsFixed(2)}'
                      : '--',
                  icon: Icons.trending_down_outlined,
                  valueColor: textPrimary,
                ),
                StatCard(
                  label: 'Monthly kWh',
                  value: account.monthlyKwh.toStringAsFixed(2),
                  unit: 'kWh',
                  icon: Icons.electric_meter_outlined,
                  valueColor: textPrimary,
                ),
                StatCard(
                  label: 'Current Rate',
                  value: '৳${slabDetails.rate.toStringAsFixed(2)}',
                  unit: '/kWh',
                  icon: Icons.bolt_outlined,
                  valueColor: _slabColor(slabDetails.index),
                  highlight: slabDetails.index >= 4,
                ),
              ],
            ),
            const SizedBox(height: 12),

            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Billing Slab',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _slabColor(slabDetails.index)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slabDetails.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _slabColor(slabDetails.index),
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: slabDetails.percentage / 100.0,
                      minHeight: 8,
                      backgroundColor: borderColor,
                      color: _slabColor(slabDetails.index),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${slabDetails.percentage.toStringAsFixed(1)}% through current slab',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: textMuted),
                  ),
                  const SizedBox(height: 16),
                  ChargeBar(monthlyKwh: account.monthlyKwh),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Consumption (last 7 days)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      )),
                  const SizedBox(height: 12),
                  UsageChart(history: history),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (isSimulation) ...[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulation Controls',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text('Simulate daily consumption and top-ups.',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: textMuted)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _simulateDay,
                            icon: const Icon(Icons.fast_forward, size: 16),
                            label: const Text('Simulate 24H'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final id =
                                  ref.read(selectedAccountIdProvider);
                              if (id != null) {
                                await ref
                                    .read(repositoryProvider)
                                    .resetCycle(id);
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Cycle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _topUpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Top-up amount (৳)',
                              prefixText: '৳ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _topUp,
                          child: const Text('Top Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Info',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      )),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Account No', value: account.accountNo),
                  _InfoRow(label: 'Meter No', value: account.meterNo),
                  _InfoRow(
                      label: 'Distributor',
                      value: _distributorName(account.distributor)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _slabColor(int index) {
    if (index <= 1) return FilamentColors.success;
    if (index <= 3) return FilamentColors.warning;
    return FilamentColors.danger;
  }

  String _distributorName(String key) {
    switch (key) {
      case 'desco': return 'DESCO (Dhaka Electric)';
      case 'dpdc': return 'DPDC (Dhaka Power)';
      default: return 'Standard Progressive';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final cardBg = isDark ? FilamentColors.darkCard : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmMono(
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
