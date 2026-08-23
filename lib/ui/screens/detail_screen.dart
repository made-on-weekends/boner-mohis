import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/calculations_helper.dart';
import '../../providers/providers.dart';
import '../theme/filament_theme.dart';
import '../widgets/charge_bar.dart';
import '../widgets/low_balance_alert.dart';
import '../widgets/usage_chart.dart';
import '../widgets/forecast_breakdown_sheet.dart';

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

    final historyAsync = ref.watch(historyStreamProvider(account.id!));
    final history = historyAsync.valueOrNull ?? [];

    final daysRemaining = CalculationsHelper.calculateDaysRemaining(
        account.balance, account.yesterdayUsage);
    final isLowBalance =
        daysRemaining != double.infinity && daysRemaining <= 2.0;
    final slabDetails = CalculationsHelper.getSlabDetails(account.monthlyKwh,
        provider: account.distributor);
    final dist = CalculationsHelper.distributors[account.distributor] ??
        CalculationsHelper.distributors['default']!;

    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    final isSimulation = account.distributor != 'desco';
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(account.lastUpdated));

    // ── Computed card metrics (mirrors extension's computeCardMetrics) ────
    final daysElapsed = history.isNotEmpty ? history.length : 1;
    final dailyAvgKwh = account.monthlyKwh / daysElapsed;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemainingInMonth =
        max(daysInMonth - (now.day - 1), 0);
    final projectedKwh =
        (account.monthlyKwh + dailyAvgKwh * daysRemainingInMonth)
            .clamp(0.0, 9999.0);
    final spendThisMonth = CalculationsHelper.calculateCost(
        account.monthlyKwh,
        provider: account.distributor);
    final forecastBill = CalculationsHelper.calculateCost(projectedKwh,
        provider: account.distributor);
    final maxLoadLastMonth = history.isNotEmpty
        ? history
                .map((h) => h.consumptionKwh)
                .reduce((a, b) => a > b ? a : b) /
            10.0
        : null;

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
                    ? FilamentColors.emberText(isDark)
                    : textMuted,
                tooltip: 'Sync live data',
                onPressed: syncLoading ? null : _triggerSync,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: FilamentColors.dangerText(isDark),
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

            // ── Sync error banner ────────────────────────────────────────
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
                    Icon(Icons.error_outline,
                        color: FilamentColors.dangerText(isDark), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sync failed: $syncError',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: FilamentColors.dangerText(isDark))),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(syncErrorProvider.notifier).state = null,
                      child: Icon(Icons.close,
                          size: 14, color: FilamentColors.dangerText(isDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Low balance alert ────────────────────────────────────────
            if (isLowBalance && !_showDismissedAlert) ...[
              LowBalanceAlert(
                daysRemaining: daysRemaining,
                balance: account.balance,
                onDismiss: () =>
                    setState(() => _showDismissedAlert = true),
              ),
              const SizedBox(height: 16),
            ],

            // ── Balance card ─────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account identity
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.nickname,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                )),
                            Text('A/C · ${account.accountNo}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Balance
                  Text('Remaining balance',
                      style:
                          GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(dist.currency,
                          style: GoogleFonts.dmMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? FilamentColors.textSecondaryDark
                                : FilamentColors.textSecondary,
                          )),
                      const SizedBox(width: 4),
                      Text(
                        account.balance.toStringAsFixed(2),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 52,
                          fontWeight: FontWeight.w500,
                          color: isLowBalance
                              ? FilamentColors.dangerText(isDark)
                              : textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ChargeBar
                  ChargeBar(
                    monthlyKwh: account.monthlyKwh,
                    loading: syncLoading,
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'as of $dateStr · ${account.distributor == "desco" ? "synced" : "manual entry"}',
                    style: GoogleFonts.dmMono(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 8-metric info grid (4×2) ─────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1
                  Row(
                    children: [
                      _InfoCell(
                        caption: 'Spend this month',
                        value:
                            '${dist.currency}${spendThisMonth.toStringAsFixed(2)}',
                        valueColor: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _InfoCell(
                        caption: 'Consumed this month',
                        value:
                            '${account.monthlyKwh.toStringAsFixed(0)} kWh',
                        valueColor: textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2
                  Row(
                    children: [
                      _InfoCell(
                        caption: 'Max load last month',
                        value: maxLoadLastMonth != null
                            ? '${maxLoadLastMonth.toStringAsFixed(2)} kW'
                            : '--',
                        valueColor: textMuted,
                      ),
                      const SizedBox(width: 8),
                      _InfoCell(
                        caption: 'Yesterday bill',
                        value:
                            '${dist.currency}${account.yesterdayUsage.toStringAsFixed(2)}',
                        valueColor: textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 3
                  Row(
                    children: [
                      _InfoCell(
                        caption: 'Forecast bill',
                        value:
                            '${dist.currency}${forecastBill.toStringAsFixed(2)}',
                        valueColor: FilamentColors.emberText(isDark),
                        tappable: true,
                        onTap: () => ForecastBreakdownSheet.show(
                          context,
                          projectedKwh: projectedKwh,
                          monthlyKwh: account.monthlyKwh,
                          dailyAvgKwh: dailyAvgKwh,
                          daysRemaining: daysRemainingInMonth,
                          provider: account.distributor,
                          currency: dist.currency,
                          mode: ForecastBreakdownMode.bill,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _InfoCell(
                        caption: 'Forecast consumption',
                        value: '${projectedKwh.toStringAsFixed(0)} kWh',
                        valueColor: FilamentColors.emberText(isDark),
                        tappable: true,
                        onTap: () => ForecastBreakdownSheet.show(
                          context,
                          projectedKwh: projectedKwh,
                          monthlyKwh: account.monthlyKwh,
                          dailyAvgKwh: dailyAvgKwh,
                          daysRemaining: daysRemainingInMonth,
                          provider: account.distributor,
                          currency: dist.currency,
                          mode: ForecastBreakdownMode.consumption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 4 — forecast remaining (full width, highlighted)
                  _InfoCell(
                    caption: 'Forecast remaining',
                    value: daysRemaining == double.infinity
                        ? '--'
                        : '${daysRemaining.toStringAsFixed(1)} days',
                    valueColor: isLowBalance
                        ? FilamentColors.dangerText(isDark)
                        : FilamentColors.successText(isDark),
                    highlighted: true,
                    isLow: isLowBalance,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Billing slab visualizer ──────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current billing tier',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _slabColor(slabDetails.index, isDark)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slabDetails.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _slabColor(slabDetails.index, isDark),
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gradient slab bar with ▼ marker
                  _GradientSlabBar(
                    percentage: slabDetails.percentage,
                    monthlyKwh: account.monthlyKwh,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 6),
                  // Range labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${slabDetails.slabMin.toInt()} kWh',
                        style:
                            GoogleFonts.dmMono(fontSize: 10, color: textMuted),
                      ),
                      Text(
                        slabDetails.slabMax == double.infinity
                            ? '∞'
                            : '${slabDetails.slabMax.toInt()} kWh',
                        style:
                            GoogleFonts.dmMono(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer: kWh consumed in tier · % used
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${account.slabUsage.toStringAsFixed(2)} kWh consumed in tier',
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: textMuted),
                      ),
                      Text(
                        '${slabDetails.percentage.toStringAsFixed(1)}% used',
                        style: GoogleFonts.dmMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _slabColor(slabDetails.index, isDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ChargeBar (full 0–600 kWh NERC bar)
                  ChargeBar(monthlyKwh: account.monthlyKwh),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Usage & Cost Trends chart ────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usage & Cost Trends',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      )),
                  const SizedBox(height: 12),
                  UsageChart(
                    history: history,
                    currency: dist.currency,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Recent usage logs ────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Usage Logs',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      )),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No usage logs recorded yet.',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: textMuted)),
                    )
                  else
                    ...history.take(10).map((item) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                          item.dateEpoch);
                      final label = DateFormat('MMM d').format(dt);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text(label,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, color: textMuted)),
                            ),
                            Expanded(
                              child: Text(
                                '${item.consumptionKwh.toStringAsFixed(2)} kWh',
                                style: GoogleFonts.dmMono(
                                    fontSize: 13,
                                    color: FilamentColors.successText(isDark)),
                              ),
                            ),
                            Text(
                              '${dist.currency}${item.cost.toStringAsFixed(2)}',
                              style: GoogleFonts.dmMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: FilamentColors.emberText(isDark)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Simulator / Live Operations ──────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSimulation
                        ? 'Simulator Controls'
                        : 'Live API Operations',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isSimulation) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: syncLoading ? null : _triggerSync,
                        icon: Icon(
                          Icons.sync,
                          size: 16,
                          color: syncLoading ? textMuted : Colors.white,
                        ),
                        label: Text(syncLoading ? 'Syncing…' : 'Sync Live'),
                      ),
                    ),
                  ] else ...[
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
                              final id = ref.read(selectedAccountIdProvider);
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
                              labelText: 'Top-up amount',
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Account Info ─────────────────────────────────────────────
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

  Color _slabColor(int index, bool isDark) {
    if (index <= 1) return FilamentColors.successText(isDark);
    if (index <= 3) return FilamentColors.emberText(isDark);
    return FilamentColors.dangerText(isDark);
  }

  String _distributorName(String key) {
    switch (key) {
      case 'desco':
        return 'DESCO (Dhaka Electric)';
      case 'dpdc':
        return 'DPDC (Dhaka Power)';
      default:
        return 'Standard Progressive';
    }
  }
}

// ─── Gradient slab bar with ▼ marker ─────────────────────────────────────────

class _GradientSlabBar extends StatelessWidget {
  final double percentage;
  final double monthlyKwh;
  final Color borderColor;

  const _GradientSlabBar({
    required this.percentage,
    required this.monthlyKwh,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final clampedPct = percentage.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marker label + arrow positioned above the bar
        LayoutBuilder(
          builder: (context, constraints) {
            final markerLeft =
                (clampedPct / 100.0 * constraints.maxWidth)
                    .clamp(0.0, constraints.maxWidth);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // The gradient progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    color: borderColor,
                    child: FractionallySizedBox(
                      widthFactor: clampedPct / 100.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2E7D3A), // deep green
                              Color(0xFF8F9B28), // yellow-green
                              Color(0xFFB25409), // amber
                              Color(0xFFC22A21), // deep red
                            ],
                            stops: [0.0, 0.3, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ▼ marker arrow + label
                Positioned(
                  left: (markerLeft - 20).clamp(0.0, constraints.maxWidth - 40),
                  top: -22,
                  child: Column(
                    children: [
                      Text(
                        '${monthlyKwh.toStringAsFixed(1)} kWh',
                        style: GoogleFonts.dmMono(
                            fontSize: 9,
                            color: textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                      Text('▼',
                          style:
                              TextStyle(fontSize: 8, color: textMuted)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── 8-cell info cell ─────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final String caption;
  final String value;
  final Color valueColor;
  final bool highlighted;
  final bool isLow;
  final bool fullWidth;
  final bool tappable;
  final VoidCallback? onTap;

  const _InfoCell({
    required this.caption,
    required this.value,
    required this.valueColor,
    this.highlighted = false,
    this.isLow = false,
    this.fullWidth = false,
    this.tappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    Color? bgColor;
    Color? highlightBorder;
    if (highlighted) {
      if (isLow) {
        bgColor = FilamentColors.danger.withValues(alpha: 0.06);
        highlightBorder = FilamentColors.danger.withValues(alpha: 0.2);
      } else {
        bgColor = FilamentColors.success.withValues(alpha: 0.06);
        highlightBorder = FilamentColors.success.withValues(alpha: 0.2);
      }
    }

    Widget cell = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: highlightBorder ?? borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: textMuted, height: 1.2)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 14, color: textMuted),
          ]
        ],
      ),
    );

    if (tappable && onTap != null) {
      return Expanded(child: GestureDetector(onTap: onTap, child: cell));
    }
    return fullWidth ? cell : Expanded(child: cell);
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

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
