import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/filament_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? valueColor;
  final bool highlight;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.valueColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final cardBg = isDark ? FilamentColors.darkCard : Colors.white;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final effectiveColor = valueColor ?? textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          left: BorderSide(
            color: highlight ? effectiveColor : borderColor,
            width: highlight ? 3 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: textMuted, height: 1.2)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: effectiveColor,
                    height: 1.0,
                  )),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: textMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
