import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/account.dart';
import '../../data/calculations_helper.dart';
import '../theme/filament_theme.dart';
import 'charge_bar.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const AccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = CalculationsHelper.calculateDaysRemaining(
        account.balance, account.yesterdayUsage);
    final isLowBalance = account.balance <= 0 ||
        (daysRemaining != double.infinity && daysRemaining <= 2.0);
    final slabDetails = CalculationsHelper.getSlabDetails(account.monthlyKwh,
        provider: account.distributor);
    final dist = CalculationsHelper.distributors[account.distributor] ??
        CalculationsHelper.distributors['default']!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final cardBg = isDark ? FilamentColors.darkCard : Colors.white;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isLowBalance
                  ? FilamentColors.danger
                  : FilamentColors.emberOrange,
              width: 3,
            ),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: FilamentColors.emberOrange.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: nickname + provider badge + low badge ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.nickname,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          dist.name,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (isLowBalance)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FilamentColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                FilamentColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12,
                              color: FilamentColors.dangerText(isDark)),
                          const SizedBox(width: 4),
                          Text('Low balance',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: FilamentColors.dangerText(isDark),
                              )),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Balance ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(dist.currency,
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? FilamentColors.textSecondaryDark
                            : FilamentColors.textSecondary,
                      )),
                  const SizedBox(width: 4),
                  Text(
                    account.balance.toStringAsFixed(2),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: isLowBalance
                          ? FilamentColors.dangerText(isDark)
                          : textPrimary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── ChargeBar ──────────────────────────────────────────────
              ChargeBar(monthlyKwh: account.monthlyKwh),

              const SizedBox(height: 12),

              // ── 2×2 Stats Grid ─────────────────────────────────────────
              Row(
                children: [
                  _StatCell(
                    caption: 'Current tier',
                    value: _tierShortLabel(slabDetails.label),
                    valueColor: _slabColor(slabDetails.index, isDark),
                  ),
                  const SizedBox(width: 8),
                  _StatCell(
                    caption: 'Consumed this month',
                    value: '${account.monthlyKwh.toStringAsFixed(0)} kWh',
                    valueColor: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatCell(
                    caption: 'Yesterday bill',
                    value: '${dist.currency}${account.yesterdayUsage.toStringAsFixed(2)}',
                    valueColor: textPrimary,
                  ),
                  const SizedBox(width: 8),
                  _StatCell(
                    caption: 'Forecast remaining',
                    value: daysRemaining == double.infinity
                        ? '--'
                        : '${daysRemaining.toStringAsFixed(1)} days',
                    valueColor: isLowBalance
                        ? FilamentColors.dangerText(isDark)
                        : FilamentColors.successText(isDark),
                    highlighted: true,
                    isLow: isLowBalance,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Tap hint ───────────────────────────────────────────────
              Center(
                child: Text(
                  'Tap to view details',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _slabColor(int index, bool isDark) {
    if (index <= 1) return FilamentColors.successText(isDark);
    if (index <= 3) return FilamentColors.emberText(isDark);
    return FilamentColors.dangerText(isDark);
  }

  /// Extracts the slab name before the parenthetical range, e.g.
  /// "First Step (51-75 kWh)" → "First Step"
  String _tierShortLabel(String label) {
    final parenIdx = label.indexOf(' (');
    return parenIdx >= 0 ? label.substring(0, parenIdx) : label;
  }
}

// ─── Reusable 2×2 stat cell ────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String caption;
  final String value;
  final Color valueColor;
  final bool highlighted;
  final bool isLow;

  const _StatCell({
    required this.caption,
    required this.value,
    required this.valueColor,
    this.highlighted = false,
    this.isLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

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

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: highlightBorder ?? borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caption,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: isDark
                        ? FilamentColors.textMutedDark
                        : FilamentColors.textMuted,
                    height: 1.2)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
