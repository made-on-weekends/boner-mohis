import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/daily_usage_history.dart';
import '../theme/filament_theme.dart';

/// Multi-line usage + cost + rate chart matching the Chrome extension.
///
/// Renders the full current month (all days pre-populated, gaps for missing
/// data). Three lines:
///   - 🟢 kWh consumption  (green solid)
///   - 🟠 Daily cost       (ember-orange solid)
///   - 🟡 Rate/unit        (gold dashed)
///
/// Includes tariff slab reference lines, interactive tap-to-tooltip,
/// and a legend row.
class UsageChart extends StatefulWidget {
  final List<DailyUsageHistory> history;
  final String currency;

  const UsageChart({
    super.key,
    required this.history,
    this.currency = '৳',
  });

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  int? _hoveredIdx;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    if (widget.history.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('Not enough historical data to display chart.',
              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
        ),
      );
    }

    // ── Derive current month from most-recent history entry ──────────────
    final latestEpoch = widget.history
        .map((h) => h.dateEpoch)
        .reduce((a, b) => a > b ? a : b);
    final latestDt = DateTime.fromMillisecondsSinceEpoch(latestEpoch);
    final year = latestDt.year;
    final month = latestDt.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // ── Build one entry per day in the month ─────────────────────────────
    final data = <_DayPoint>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final dayDt = DateTime(year, month, day);
      final dayEpoch = dayDt.millisecondsSinceEpoch;
      // Find a matching history entry (compare date by Y/M/D)
      DailyUsageHistory? record;
      for (final h in widget.history) {
        final hDt = DateTime.fromMillisecondsSinceEpoch(h.dateEpoch);
        if (hDt.year == year && hDt.month == month && hDt.day == day) {
          record = h;
          break;
        }
      }
      data.add(_DayPoint(
        day: day,
        epoch: dayEpoch,
        hasData: record != null,
        consumptionKwh: record?.consumptionKwh,
        cost: record?.cost,
      ));
    }

    // ── Scales ────────────────────────────────────────────────────────────
    final validKwh = data
        .where((d) => d.hasData)
        .map((d) => d.consumptionKwh!)
        .toList();
    final validCost =
        data.where((d) => d.hasData).map((d) => d.cost!).toList();

    final maxKwh = validKwh.isEmpty
        ? 1.0
        : validKwh.reduce(max) * 1.15;
    final maxCost = validCost.isEmpty
        ? 1.0
        : validCost.reduce(max);
    const maxRate = 20.0; // ৳/kWh — covers all tariff slabs

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chart canvas ─────────────────────────────────────────────────
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 180.0;
              const padL = 36.0;
              const padR = 36.0;
              const padT = 20.0;
              const padB = 24.0;
              final cw = w - padL - padR;
              final n = data.length;

              double getX(int i) =>
                  n <= 1 ? padL + cw / 2 : padL + (i / (n - 1)) * cw;

              return GestureDetector(
                onTapDown: (details) {
                  // Find closest data point with data
                  final tapX = details.localPosition.dx;
                  int? closest;
                  double minDist = double.infinity;
                  for (int i = 0; i < data.length; i++) {
                    if (!data[i].hasData) continue;
                    final dx = (getX(i) - tapX).abs();
                    if (dx < minDist) {
                      minDist = dx;
                      closest = i;
                    }
                  }
                  setState(() => _hoveredIdx = closest);
                },
                onTapUp: (_) =>
                    Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _hoveredIdx = null);
                }),
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _ChartPainter(
                    data: data,
                    maxKwh: maxKwh,
                    maxCost: maxCost,
                    maxRate: maxRate,
                    hoveredIdx: _hoveredIdx,
                    currency: widget.currency,
                    isDark: isDark,
                    daysInMonth: daysInMonth,
                    padL: padL,
                    padR: padR,
                    padT: padT,
                    padB: padB,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Tooltip (shown below chart when a point is selected) ─────────
        if (_hoveredIdx != null && data[_hoveredIdx!].hasData) ...[
          const SizedBox(height: 8),
          _Tooltip(
            point: data[_hoveredIdx!],
            currency: widget.currency,
            isDark: isDark,
          ),
        ],

        const SizedBox(height: 10),

        // ── Legend ───────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
                color: FilamentColors.successText(isDark),
                label: 'Usage (kWh)',
                dashed: false),
            const SizedBox(width: 16),
            _LegendItem(
                color: FilamentColors.emberText(isDark),
                label: 'Cost (${widget.currency})',
                dashed: false),
            const SizedBox(width: 16),
            const _LegendItem(
                color: Color(0xFFD4AF37),
                label: 'Rate/unit',
                dashed: true),
          ],
        ),
      ],
    );
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final List<_DayPoint> data;
  final double maxKwh, maxCost, maxRate;
  final int? hoveredIdx;
  final String currency;
  final bool isDark;
  final int daysInMonth;
  final double padL, padR, padT, padB;

  const _ChartPainter({
    required this.data,
    required this.maxKwh,
    required this.maxCost,
    required this.maxRate,
    required this.hoveredIdx,
    required this.currency,
    required this.isDark,
    required this.daysInMonth,
    required this.padL,
    required this.padR,
    required this.padT,
    required this.padB,
  });

  double _getX(int i, double cw) {
    final n = data.length;
    return n <= 1 ? padL + cw / 2 : padL + (i / (n - 1)) * cw;
  }

  double _getYKwh(double v, double ch) =>
      padT + ch - (v / maxKwh.clamp(0.001, double.infinity)) * ch;
  double _getYCost(double v, double ch) =>
      padT + ch - (v / maxCost.clamp(0.001, double.infinity)) * ch;
  double _getYRate(double v, double ch) => padT + ch - (v / maxRate) * ch;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cw = w - padL - padR;
    final ch = h - padT - padB;

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.06);
    final axisLabelStyle = TextStyle(
      fontSize: 8,
      color: isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted,
      fontFamily: 'DM Mono',
    );

    // ── Horizontal grid lines ─────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final pct in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = padT + pct * ch;
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);
    }

    // ── Tariff slab reference lines (gold dashed) ─────────────────────────
    const slabRates = [5.26, 8.50, 9.10];
    final slabPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final rate in slabRates) {
      final y = _getYRate(rate, ch);
      if (y < padT || y > padT + ch) continue;
      _drawDashedLine(canvas, Offset(padL, y), Offset(w - padR, y),
          slabPaint, 3, 3);

      // Rate label on right
      _drawText(
        canvas,
        rate.toStringAsFixed(2),
        Offset(w - padR + 2, y - 4),
        TextStyle(
          fontSize: 6,
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
          fontFamily: 'DM Mono',
        ),
      );
    }

    // ── X axis labels ─────────────────────────────────────────────────────
    for (int i = 0; i < data.length; i++) {
      final day = data[i].day;
      final showLabel = day == 1 || day == daysInMonth || day % 5 == 0;
      if (!showLabel) continue;
      final x = _getX(i, cw);
      _drawText(
        canvas,
        '$day',
        Offset(x - 4, h - padB + 4),
        axisLabelStyle,
      );
    }

    // ── Y axis labels (left = kWh, right = currency) ──────────────────────
    _drawText(
      canvas,
      'kWh',
      Offset(0, padT - 14),
      TextStyle(
        fontSize: 8,
        color: FilamentColors.successText(isDark),
        fontFamily: 'DM Sans',
      ),
    );
    _drawText(
      canvas,
      currency,
      Offset(w - padR + 2, padT - 14),
      TextStyle(
        fontSize: 8,
        color: FilamentColors.emberText(isDark),
        fontFamily: 'DM Sans',
      ),
    );

    // ── Build line paths ──────────────────────────────────────────────────
    final kwhPath = Path();
    final costPath = Path();
    final ratePath = Path();
    bool kwhStarted = false, costStarted = false, rateStarted = false;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      if (!d.hasData) continue;

      final x = _getX(i, cw);
      final yKwh = _getYKwh(d.consumptionKwh!, ch);
      final yCost = _getYCost(d.cost!, ch);
      final rate =
          d.consumptionKwh! > 0 ? d.cost! / d.consumptionKwh! : 0.0;
      final yRate = _getYRate(rate, ch);

      if (yKwh.isFinite) {
        if (!kwhStarted) {
          kwhPath.moveTo(x, yKwh);
          kwhStarted = true;
        } else {
          kwhPath.lineTo(x, yKwh);
        }
      }
      if (yCost.isFinite) {
        if (!costStarted) {
          costPath.moveTo(x, yCost);
          costStarted = true;
        } else {
          costPath.lineTo(x, yCost);
        }
      }
      if (yRate.isFinite) {
        if (!rateStarted) {
          ratePath.moveTo(x, yRate);
          rateStarted = true;
        } else {
          ratePath.lineTo(x, yRate);
        }
      }
    }

    // ── Draw lines ────────────────────────────────────────────────────────
    final kwhPaint = Paint()
      ..color = FilamentColors.successText(isDark)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(kwhPath, kwhPaint);

    final costPaint = Paint()
      ..color = FilamentColors.emberText(isDark)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(costPath, costPaint);

    final ratePaintDashed = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, ratePath, ratePaintDashed, 3, 3);

    // ── Data dots & hover indicator ───────────────────────────────────────
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      if (!d.hasData) continue;

      final x = _getX(i, cw);
      final yKwh = _getYKwh(d.consumptionKwh!, ch);
      final yCost = _getYCost(d.cost!, ch);
      final rate =
          d.consumptionKwh! > 0 ? d.cost! / d.consumptionKwh! : 0.0;
      final yRate = _getYRate(rate, ch);
      final isHovered = hoveredIdx == i;

      if (isHovered) {
        // Vertical dashed indicator line
        final hoverLinePaint = Paint()
          ..color = gridColor
          ..strokeWidth = 1.5;
        _drawDashedLine(
          canvas,
          Offset(x, padT),
          Offset(x, padT + ch),
          hoverLinePaint,
          3,
          3,
        );
      }

      final r = isHovered ? 4.0 : 1.5;
      final rRate = isHovered ? 3.0 : 1.0;

      _drawDot(canvas, Offset(x, yKwh), r, FilamentColors.successText(isDark), isDark);
      _drawDot(canvas, Offset(x, yCost), r, FilamentColors.emberText(isDark), isDark);
      _drawDot(canvas, Offset(x, yRate), rRate, const Color(0xFFD4AF37), isDark);
    }
  }

  void _drawDot(
      Canvas canvas, Offset center, double r, Color stroke, bool isDark) {
    final fill = isDark ? FilamentColors.darkCard : Colors.white;
    canvas.drawCircle(center, r,
        Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final nx = dx / len;
    final ny = dy / len;
    double traveled = 0;
    bool drawing = true;
    while (traveled < len) {
      final segLen = drawing ? dash : gap;
      final end = min(traveled + segLen, len);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + nx * traveled, p1.dy + ny * traveled),
          Offset(p1.dx + nx * end, p1.dy + ny * end),
          paint,
        );
      }
      traveled = end;
      drawing = !drawing;
    }
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < metric.length) {
        final seg = draw ? dash : gap;
        final end = min(d + seg, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(d, end), paint);
        }
        d = end;
        draw = !draw;
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.hoveredIdx != hoveredIdx ||
      old.data != data ||
      old.isDark != isDark;
}

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _Tooltip extends StatelessWidget {
  final _DayPoint point;
  final String currency;
  final bool isDark;

  const _Tooltip({
    required this.point,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;
    final bg = isDark ? FilamentColors.darkCard : Colors.white;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final dt = DateTime.fromMillisecondsSinceEpoch(point.epoch);
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final rate = point.consumptionKwh! > 0
        ? point.cost! / point.consumptionKwh!
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr,
              style: GoogleFonts.dmMono(fontSize: 11, color: textMuted)),
          const SizedBox(height: 6),
          _TooltipRow(
            color: FilamentColors.successText(isDark),
            label: 'Usage',
            value: '${point.consumptionKwh!.toStringAsFixed(2)} kWh',
            isDark: isDark,
          ),
          _TooltipRow(
            color: FilamentColors.emberText(isDark),
            label: 'Cost',
            value: '$currency${point.cost!.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          _TooltipRow(
            color: const Color(0xFFD4AF37),
            label: 'Rate',
            value: '$currency${rate.toStringAsFixed(2)}/unit',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;
  const _TooltipRow(
      {required this.color,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.dmSans(fontSize: 11, color: textMuted)),
          Text(value,
              style: GoogleFonts.dmMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textPrimary)),
        ],
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem(
      {required this.color, required this.label, required this.dashed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(20, 2),
          painter: _LinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 10, color: textMuted)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;
  const _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!dashed) {
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      double x = 0;
      bool draw = true;
      while (x < size.width) {
        if (draw) {
          canvas.drawLine(Offset(x, size.height / 2),
              Offset(min(x + 4, size.width), size.height / 2), paint);
        }
        x += draw ? 4 : 3;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.color != color || old.dashed != dashed;
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _DayPoint {
  final int day;
  final int epoch;
  final bool hasData;
  final double? consumptionKwh;
  final double? cost;

  const _DayPoint({
    required this.day,
    required this.epoch,
    required this.hasData,
    this.consumptionKwh,
    this.cost,
  });
}
