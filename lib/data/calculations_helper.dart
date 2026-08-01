import 'dart:math';
import 'models/slab_models.dart';

/// Port of CalculationsHelper.kt — BPDB Category-A Residential 7-slab tariff.
/// See docs/TARIFF.md for full specification and lifeline bypass rule.
class CalculationsHelper {
  CalculationsHelper._();

  static const Map<String, DistributorConfig> distributors = {
    'default': DistributorConfig(
      name: 'Standard Progressive Utility',
      currency: '৳',
      slabs: [
        Slab(50.0, 4.63),
        Slab(75.0, 5.26),
        Slab(200.0, 8.50),
        Slab(300.0, 9.10),
        Slab(400.0, 9.62),
        Slab(600.0, 15.01),
        Slab(double.infinity, 17.35),
      ],
    ),
    'dpdc': DistributorConfig(
      name: 'DPDC (Dhaka Power)',
      currency: '৳',
      slabs: [
        Slab(50.0, 4.63),
        Slab(75.0, 5.26),
        Slab(200.0, 8.50),
        Slab(300.0, 9.10),
        Slab(400.0, 9.62),
        Slab(600.0, 15.01),
        Slab(double.infinity, 17.35),
      ],
    ),
    'desco': DistributorConfig(
      name: 'DESCO (Dhaka Electric)',
      currency: '৳',
      slabs: [
        Slab(50.0, 4.63),
        Slab(75.0, 5.26),
        Slab(200.0, 8.50),
        Slab(300.0, 9.10),
        Slab(400.0, 9.62),
        Slab(600.0, 15.01),
        Slab(double.infinity, 17.35),
      ],
    ),
  };

  static const _slabNames = [
    'Lifeline',
    'First Step',
    'Second Step',
    'Third Step',
    'Fourth Step',
    'Fifth Step',
    'Sixth Step',
  ];

  static double calculateCost(double kwh, {String provider = 'default'}) {
    final config = distributors[provider] ?? distributors['default']!;
    double remaining = kwh;
    double totalCost = 0.0;

    final isLifeline = kwh <= 50.0;
    final startIdx = isLifeline ? 0 : 1;
    double prevLimit = 0.0;

    for (int i = startIdx; i < config.slabs.length; i++) {
      final slab = config.slabs[i];
      final rangeWidth = slab.limit - prevLimit;
      final consumedInSlab = min(remaining, rangeWidth);
      totalCost += consumedInSlab * slab.rate;
      remaining -= consumedInSlab;
      prevLimit = slab.limit;
      if (remaining <= 0.0) break;
    }

    return (totalCost * 100).roundToDouble() / 100.0;
  }

  static SlabDetails getSlabDetails(double kwh,
      {String provider = 'default'}) {
    final config = distributors[provider] ?? distributors['default']!;

    int index = 0;
    for (int i = 0; i < config.slabs.length; i++) {
      if (kwh <= config.slabs[i].limit ||
          config.slabs[i].limit == double.infinity) {
        index = i;
        break;
      }
    }

    final slab = config.slabs[index];

    final slabRanges = [
      const _SlabRange('Lifeline', 0.0, 50.0),
      _SlabRange('First Step', kwh > 50.0 ? 0.0 : 51.0, 75.0),
      const _SlabRange('Second Step', 76.0, 200.0),
      const _SlabRange('Third Step', 201.0, 300.0),
      const _SlabRange('Fourth Step', 301.0, 400.0),
      const _SlabRange('Fifth Step', 401.0, 600.0),
      const _SlabRange('Sixth Step', 601.0, double.infinity),
    ];

    final rangeConfig = index < slabRanges.length
        ? slabRanges[index]
        : _SlabRange('Slab ${index + 1}', 0.0, slab.limit);

    final slabMin = rangeConfig.min;
    final slabMax = rangeConfig.max;
    final rangeWidth = slabMax - slabMin;

    final percentage = rangeWidth == double.infinity
        ? 100.0
        : min(100.0, max(0.0, ((kwh - slabMin) / rangeWidth) * 100.0));

    final label = slabMax == double.infinity
        ? '${rangeConfig.name} (>${(slabMin - 1).toInt()} kWh)'
        : '${rangeConfig.name} (${slabMin.toInt()}–${slabMax.toInt()} kWh)';

    return SlabDetails(
      index: index,
      rate: slab.rate,
      slabMin: slabMin,
      slabMax: slabMax,
      percentage: (percentage * 10).roundToDouble() / 10.0,
      label: label,
    );
  }

  static List<SlabBreakdownLine> getSlabBreakdown(double kwh,
      {String provider = 'default'}) {
    final config = distributors[provider] ?? distributors['default']!;
    double remaining = kwh;
    final lines = <SlabBreakdownLine>[];

    final isLifeline = kwh <= 50.0;
    final startIdx = isLifeline ? 0 : 1;
    double prevLimit = 0.0;

    for (int i = startIdx; i < config.slabs.length; i++) {
      final slab = config.slabs[i];
      final rangeWidth = slab.limit - prevLimit;
      final units = min(remaining, rangeWidth);

      if (units > 0.0) {
        final cost = units * slab.rate;
        final name = i < _slabNames.length ? _slabNames[i] : 'Slab ${i + 1}';
        lines.add(SlabBreakdownLine(
          name: name,
          units: (units * 100).roundToDouble() / 100.0,
          rate: slab.rate,
          cost: (cost * 100).roundToDouble() / 100.0,
        ));
      }

      remaining -= units;
      prevLimit = slab.limit;
      if (remaining <= 0.0) break;
    }

    return lines;
  }

  static double calculateDaysRemaining(
      double balance, double yesterdayUsage) {
    if (yesterdayUsage <= 0.0) return double.infinity;
    return (balance / yesterdayUsage * 10).roundToDouble() / 10.0;
  }
}

class _SlabRange {
  final String name;
  final double min;
  final double max;
  const _SlabRange(this.name, this.min, this.max);
}
