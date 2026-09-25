import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safebite_app/viewmodels/home_viewmodel.dart';
import 'package:safebite_app/views/ingredient_review_screen.dart';

void main() {
  testWidgets('IngredientReviewScreen displays chips and allows editing', (tester) async {
    final container = ProviderContainer();
    container.read(homeViewModelProvider.notifier).setTarget('baby');
    container.read(homeViewModelProvider.notifier).setAgeRange('6 - 12 months', 8);
    container.read(homeViewModelProvider.notifier).setScannedIngredients([
      'Organic Apples',
      'Raw Honey',
      'Cane Sugar',
      'Wheat Flour',
      'Yellow 5 (Tartrazine)',
      'Natural Flavor',
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: IngredientReviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and profile
    expect(find.text('Review Ingredients'), findsOneWidget);
    expect(find.text('6 Ingredients Detected'), findsOneWidget);
    expect(find.text('👶 Baby (6 - 12 months)'), findsOneWidget);

    // Verify all 6 chips are present
    expect(find.text('Organic Apples'), findsOneWidget);
    expect(find.text('Raw Honey'), findsOneWidget);
    expect(find.text('Cane Sugar'), findsOneWidget);
    expect(find.text('Wheat Flour'), findsOneWidget);
    expect(find.text('Yellow 5 (Tartrazine)'), findsOneWidget);
    expect(find.text('Natural Flavor'), findsOneWidget);

    // Test removing a chip (e.g. Wheat Flour)
    final wheatFlourDeleteIcon = find.descendant(
      of: find.widgetWithText(Chip, 'Wheat Flour'),
      matching: find.byIcon(Icons.cancel),
    );
    await tester.tap(wheatFlourDeleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Wheat Flour'), findsNothing);
    expect(find.text('5 Ingredients Detected'), findsOneWidget);

    // Test adding a chip manually
    await tester.enterText(find.byType(TextField), 'Oat Milk');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Oat Milk'), findsOneWidget);
    expect(find.text('6 Ingredients Detected'), findsOneWidget);
  });
}
