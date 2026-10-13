import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/filament_theme.dart';

/// NERC progressive tier-proportional consumption bar.
/// Splits into 6 segments matching Bangladesh progressive tariff ranges
/// (0–50, 50–75, 75–200, 200–300, 300–400, 400–600 kWh).
/// Each segment's fill color reveals a portion of the green→red gradient.
class ChargeBar extends StatelessWidget {
  final double monthlyKwh;
  final double maxKwh;

  /// When true, all segments render empty (grey) — used during live sync.
  final bool loading;

  const ChargeBar({
    super.key,
    required this.monthlyKwh,
    this.maxKwh = 600.0,
    this.loading = false,
  });

  static const List<_TierSegment> _tiers = [
    _TierSegment(min: 0,   max: 50,  weight: 50 / 600),
    _TierSegment(min: 50,  max: 75,  weight: 25 / 600),
    _TierSegment(min: 75,  max: 200, weight: 125 / 600),
    _TierSegment(min: 200, max: 300, weight: 100 / 600),
    _TierSegment(min: 300, max: 400, weight: 100 / 600),
    _TierSegment(min: 400, max: 600, weight: 200 / 600),
  ];

  /// Interpolates a green→amber→red colour based on kWh value (0–600).
  Color _colorForKwh(double val, bool isDark) {
    final clamped = val.clamp(0.0, 600.0);
    final okColor = isDark ? FilamentColors.successOnDark : FilamentColors.success;
    final emberColor = isDark ? FilamentColors.emberOrangeDark : FilamentColors.emberOrange;
    final dangerColor = isDark ? FilamentColors.dangerOnDark : FilamentColors.danger;

    if (clamped <= 300) {
      final t = clamped / 300.0;
      return Color.lerp(okColor, emberColor, t)!;
    } else {
      final t = (clamped - 300) / 300.0;
      return Color.lerp(emberColor, dangerColor, t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final textMuted = isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Monthly Usage',
                style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
            Text(loading ? '-- kWh' : '${monthlyKwh.toStringAsFixed(1)} kWh',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _tiers.asMap().entries.map((entry) {
            final i = entry.key;
            final tier = entry.value;
            final rangeWidth = (tier.max - tier.min).toDouble();
            final consumed = loading
                ? 0.0
                : (monthlyKwh - tier.min).clamp(0.0, rangeWidth);
            final fillFraction = consumed / rangeWidth;

            final startColor = _colorForKwh(tier.min.toDouble(), isDark);
            final endColor = _colorForKwh(tier.max.toDouble(), isDark);

            return Expanded(
              flex: (tier.weight * 600).round(),
              child: Container(
                margin: EdgeInsets.only(right: i < _tiers.length - 1 ? 3 : 0),
                height: 8,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: FractionallySizedBox(
                    widthFactor: fillFraction,
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [startColor, endColor],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0',
                style: GoogleFonts.dmSans(fontSize: 10, color: textMuted)),
            Text('${maxKwh.toInt()} kWh',
                style: GoogleFonts.dmSans(fontSize: 10, color: textMuted)),
          ],
        ),
      ],
    );
  }
}

class _TierSegment {
  final num min;
  final num max;
  final double weight;
  const _TierSegment({required this.min, required this.max, required this.weight});
}
