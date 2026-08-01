import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/filament_theme.dart';

class ChargeBar extends StatelessWidget {
  final double monthlyKwh;
  final double maxKwh;

  const ChargeBar({
    super.key,
    required this.monthlyKwh,
    this.maxKwh = 600.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    const segments = 6;
    final kwhPerSegment = maxKwh / segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Monthly Usage',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: FilamentColors.textMuted)),
            Text('${monthlyKwh.toStringAsFixed(1)} kWh',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: List.generate(segments, (i) {
                final segStart = i * kwhPerSegment;
                final fillFraction = ((monthlyKwh - segStart) / kwhPerSegment)
                    .clamp(0.0, 1.0);
                final segColor = _segmentColor(i, segments);

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < segments - 1 ? 3 : 0),
                    height: 10,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FractionallySizedBox(
                        widthFactor: fillFraction,
                        alignment: Alignment.centerLeft,
                        child: Container(color: segColor),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: GoogleFonts.dmSans(fontSize: 10, color: FilamentColors.textMuted)),
            Text('${maxKwh.toInt()} kWh',
                style: GoogleFonts.dmSans(fontSize: 10, color: FilamentColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Color _segmentColor(int index, int total) {
    final t = index / (total - 1);
    if (t < 0.5) {
      return Color.lerp(FilamentColors.success,
          FilamentColors.warning, t * 2)!;
    } else {
      return Color.lerp(
          FilamentColors.warning, FilamentColors.danger, (t - 0.5) * 2)!;
    }
  }
}
