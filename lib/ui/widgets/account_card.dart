import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/account.dart';
import '../../data/calculations_helper.dart';
import '../theme/filament_theme.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const AccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = CalculationsHelper.calculateDaysRemaining(
        account.balance, account.yesterdayUsage);
    final isLowBalance =
        daysRemaining != double.infinity && daysRemaining <= 2.0;
    final slabDetails = CalculationsHelper.getSlabDetails(account.monthlyKwh,
        provider: account.distributor);

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
          borderRadius: BorderRadius.circular(16),
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
                          _distributorName(account.distributor),
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
                            color: FilamentColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: FilamentColors.danger),
                          const SizedBox(width: 4),
                          Text('LOW',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: FilamentColors.danger,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('৳',
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: FilamentColors.textSecondary,
                      )),
                  const SizedBox(width: 4),
                  Text(
                    account.balance.toStringAsFixed(2),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: isLowBalance
                          ? FilamentColors.danger
                          : textPrimary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    label: 'Days Left',
                    value: daysRemaining == double.infinity
                        ? '--'
                        : daysRemaining.toStringAsFixed(1),
                    icon: Icons.schedule_outlined,
                    color: isLowBalance
                        ? FilamentColors.danger
                        : FilamentColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Slab',
                    value: _slabShortLabel(slabDetails.label),
                    icon: Icons.bolt_outlined,
                    color: _slabColor(slabDetails.index),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Monthly',
                    value: '${account.monthlyKwh.toStringAsFixed(1)} kWh',
                    icon: Icons.electric_meter_outlined,
                    color: FilamentColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  Color _slabColor(int index) {
    if (index <= 1) return FilamentColors.success;
    if (index <= 3) return FilamentColors.warning;
    return FilamentColors.danger;
  }

  String _slabShortLabel(String label) {
    if (label.startsWith('Lifeline')) return 'Lifeline';
    if (label.startsWith('First')) return '1st Step';
    if (label.startsWith('Second')) return '2nd Step';
    if (label.startsWith('Third')) return '3rd Step';
    if (label.startsWith('Fourth')) return '4th Step';
    if (label.startsWith('Fifth')) return '5th Step';
    if (label.startsWith('Sixth')) return '6th Step';
    return label.split(' ').first;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: FilamentColors.textMuted,
                          height: 1.2)),
                  Text(value,
                      style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                          height: 1.3),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
