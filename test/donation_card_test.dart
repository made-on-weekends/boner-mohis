import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boner_mohis/ui/widgets/donation_card.dart';

void main() {
  group('DonationCard Widget Tests', () {
    testWidgets('renders donation card elements and triggers onTap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonationCard(
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Enjoying BonerMohis?'), findsOneWidget);
      expect(find.text('Support BonerMohis development'), findsOneWidget);
      expect(find.text('Donate ☕'), findsOneWidget);

      // Tap on the button
      await tester.tap(find.text('Donate ☕'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Reset and tap on the card text/inkwell
      tapped = false;
      await tester.tap(find.text('Enjoying BonerMohis?'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
