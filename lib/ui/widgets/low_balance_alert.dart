import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/filament_theme.dart';

class LowBalanceAlert extends StatelessWidget {
  final double daysRemaining;
  final double balance;
  final VoidCallback? onDismiss;

  const LowBalanceAlert({
    super.key,
    required this.daysRemaining,
    required this.balance,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = daysRemaining <= 1.0;
    final color = isCritical ? FilamentColors.danger : FilamentColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'Critical — Balance Almost Empty!' : 'Low Balance Warning',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysRemaining == double.infinity
                      ? 'Top up soon to avoid outage.'
                      : '৳${balance.toStringAsFixed(2)} remaining — approx. ${daysRemaining.toStringAsFixed(1)} day${daysRemaining == 1.0 ? '' : 's'} at current usage.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: color),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 16, color: color),
            ),
        ],
      ),
    );
  }
}
