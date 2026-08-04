import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/calculations_helper.dart';
import '../../data/models/slab_models.dart';
import '../theme/filament_theme.dart';

/// Shows a bottom sheet with the tiered billing breakdown table.
/// Mirrors the extension's hover tooltip on the "Forecast bill" info card.
///
/// Usage:
///   ForecastBreakdownSheet.show(
///     context,
///     projectedKwh: 245.0,
///     provider: 'desco',
///     currency: '৳',
///     mode: ForecastBreakdownMode.bill,   // or .consumption
///   );
enum ForecastBreakdownMode { bill, consumption }

class ForecastBreakdownSheet extends StatelessWidget {
  final double projectedKwh;
  final double monthlyKwh;
  final double dailyAvgKwh;
  final int daysRemaining;
  final String provider;
  final String currency;
  final ForecastBreakdownMode mode;

  const ForecastBreakdownSheet({
    super.key,
    required this.projectedKwh,
    required this.monthlyKwh,
    required this.dailyAvgKwh,
    required this.daysRemaining,
    required this.provider,
    required this.currency,
    this.mode = ForecastBreakdownMode.bill,
  });

  static void show(
    BuildContext context, {
    required double projectedKwh,
    required double monthlyKwh,
    required double dailyAvgKwh,
    required int daysRemaining,
    required String provider,
    required String currency,
    ForecastBreakdownMode mode = ForecastBreakdownMode.bill,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ForecastBreakdownSheet(
        projectedKwh: projectedKwh,
        monthlyKwh: monthlyKwh,
        dailyAvgKwh: dailyAvgKwh,
        daysRemaining: daysRemaining,
        provider: provider,
        currency: currency,
        mode: mode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? FilamentColors.darkCard : Colors.white;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    final totalCost = CalculationsHelper.calculateCost(projectedKwh,
        provider: provider);
    final breakdown = CalculationsHelper.getSlabBreakdown(projectedKwh,
        provider: provider);

    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                mode == ForecastBreakdownMode.bill
                    ? 'Tiered Billing Breakdown'
                    : 'Forecast Consumption Breakdown',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${projectedKwh.toStringAsFixed(0)} kWh projected for this month',
                style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),

              if (mode == ForecastBreakdownMode.bill) ...[
                // ── Billing breakdown table ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _TableHeader(
                        borderColor: borderColor,
                        textMuted: textMuted,
                      ),
                      ...breakdown.asMap().entries.map((entry) {
                        final i = entry.key;
                        final row = entry.value;
                        final isLast = i == breakdown.length - 1;
                        return _TableRow(
                          row: row,
                          currency: currency,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          isLast: isLast,
                          isDark: isDark,
                        );
                      }),
                      // Total row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: FilamentColors.emberOrange
                              .withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('Total',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  )),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '$currency${totalCost.toStringAsFixed(2)}',
                                style: GoogleFonts.dmMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FilamentColors.emberOrange,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ── Consumption breakdown table ─────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _ConsRow(
                          label: 'Consumed so far',
                          value: '${monthlyKwh.toStringAsFixed(1)} kWh',
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          isLast: false),
                      _ConsRow(
                          label: 'Daily average',
                          value:
                              '${dailyAvgKwh.toStringAsFixed(2)} kWh/day',
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          isLast: false),
                      _ConsRow(
                          label: 'Days remaining',
                          value: '$daysRemaining days',
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          isLast: false),
                      _ConsRow(
                          label: 'Projected remainder',
                          value:
                              '${(dailyAvgKwh * daysRemaining).toStringAsFixed(1)} kWh',
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          isLast: false),
                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: FilamentColors.emberOrange
                              .withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Forecast Total',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                )),
                            Text(
                              '${projectedKwh.toStringAsFixed(1)} kWh',
                              style: GoogleFonts.dmMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FilamentColors.emberOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Formula: Consumed + (Avg × Days Left)',
                  style: GoogleFonts.dmSans(fontSize: 11, color: textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Table sub-widgets ────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final Color borderColor;
  final Color textMuted;
  const _TableHeader({required this.borderColor, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Tier',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted))),
          Expanded(
              flex: 2,
              child: Text('Units',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted))),
          Expanded(
              flex: 1,
              child: Text('Rate',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted))),
          Expanded(
              flex: 2,
              child: Text('Cost',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final SlabBreakdownLine row;
  final String currency;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;
  final bool isLast;
  final bool isDark;

  const _TableRow({
    required this.row,
    required this.currency,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(row.name,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: textPrimary))),
          Expanded(
              flex: 2,
              child: Text('${row.units.toStringAsFixed(1)} kWh',
                  style: GoogleFonts.dmMono(
                      fontSize: 12, color: textMuted))),
          Expanded(
              flex: 1,
              child: Text('$currency${row.rate.toStringAsFixed(2)}',
                  style: GoogleFonts.dmMono(
                      fontSize: 12, color: textMuted))),
          Expanded(
              flex: 2,
              child: Text('$currency${row.cost.toStringAsFixed(2)}',
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FilamentColors.emberOrange,
                  ),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _ConsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;
  final bool isLast;

  const _ConsRow({
    required this.label,
    required this.value,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
          Text(value,
              style: GoogleFonts.dmMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textPrimary)),
        ],
      ),
    );
  }
}
