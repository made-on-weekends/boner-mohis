/// Data models for slab calculations — mirrors CalculationsHelper.kt data classes.
library;

class Slab {
  final double limit;
  final double rate;
  const Slab(this.limit, this.rate);
}

class SlabBreakdownLine {
  final String name;
  final double units;
  final double rate;
  final double cost;

  const SlabBreakdownLine({
    required this.name,
    required this.units,
    required this.rate,
    required this.cost,
  });
}

class SlabDetails {
  final int index;
  final double rate;
  final double slabMin;
  final double slabMax;
  final double percentage;
  final String label;

  const SlabDetails({
    required this.index,
    required this.rate,
    required this.slabMin,
    required this.slabMax,
    required this.percentage,
    required this.label,
  });
}

class DistributorConfig {
  final String name;
  final String currency;
  final List<Slab> slabs;

  const DistributorConfig({
    required this.name,
    required this.currency,
    required this.slabs,
  });
}
