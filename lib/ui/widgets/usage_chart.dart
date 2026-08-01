import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/daily_usage_history.dart';
import '../theme/filament_theme.dart';

class UsageChart extends StatelessWidget {
  final List<DailyUsageHistory> history;

  const UsageChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final gridColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    final recent = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    if (recent.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('No history yet',
              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
        ),
      );
    }

    final maxY = recent
        .map((h) => h.consumptionKwh)
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxY > 0 ? (maxY * 1.25).ceilToDouble() : 10.0;

    final bars = recent.asMap().entries.map((entry) {
      final i = entry.key;
      final h = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: h.consumptionKwh,
            width: 14,
            color: FilamentColors.emberOrange,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: chartMax,
              color: gridColor.withValues(alpha: 0.4),
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColor,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.dmMono(
                          fontSize: 9, color: textMuted),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < recent.length) {
                    final epoch = recent[idx].dateEpoch;
                    final dt =
                        DateTime.fromMillisecondsSinceEpoch(epoch);
                    final label =
                        '${dt.day}/${dt.month}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label,
                          style: GoogleFonts.dmSans(
                              fontSize: 9, color: textMuted)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark
                  ? FilamentColors.darkCard
                  : FilamentColors.warmPaper,
              tooltipBorder: BorderSide(color: gridColor),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(2)} kWh',
                  GoogleFonts.dmMono(
                    fontSize: 11,
                    color: FilamentColors.emberOrange,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
