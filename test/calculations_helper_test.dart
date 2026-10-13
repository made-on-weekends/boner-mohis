import 'package:flutter_test/flutter_test.dart';
import 'package:boner_mohis/data/calculations_helper.dart';

void main() {
  group('CalculationsHelper Tests', () {
    test('Lifeline tariff applies when usage <= 50 kWh', () {
      final cost = CalculationsHelper.calculateCost(40.0);
      // 40 * 4.63 = 185.20
      expect(cost, closeTo(185.20, 0.01));
    });

    test('First Step tariff applies when usage > 50 kWh (Lifeline bypassed)', () {
      final cost = CalculationsHelper.calculateCost(124.01);
      // 75 * 5.26 = 394.50
      // (124.01 - 75) * 8.50 = 49.01 * 8.50 = 416.585
      // Total = 811.085 => 811.09
      expect(cost, closeTo(811.09, 0.02));
    });

    test('Days remaining calculation handles zero usage edge case', () {
      final days = CalculationsHelper.calculateDaysRemaining(500.0, 0.0);
      expect(days, equals(double.infinity));
    });

    test('Days remaining calculation computes correct ratio', () {
      final days = CalculationsHelper.calculateDaysRemaining(500.0, 250.0);
      expect(days, equals(2.0));
    });

    test('Slab details identifies Lifeline correctly', () {
      final details = CalculationsHelper.getSlabDetails(40.0);
      expect(details.index, equals(0));
      expect(details.label, contains('Lifeline'));
    });

    test('Slab details identifies Second Step correctly', () {
      final details = CalculationsHelper.getSlabDetails(120.0);
      expect(details.index, equals(2));
      expect(details.label, contains('Second Step'));
    });
  });
}
