import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('AI Lab Hub smoke test and navigation to Day 1 & Day 2', (WidgetTester tester) async {
    await tester.pumpWidget(const AiLabApp());

    // 1. Verify Home screen cards render
    expect(find.text('AI Lab'), findsOneWidget);
    expect(find.text('AI Web Summarizer'), findsOneWidget);
    expect(find.text('Smart Shop Assistant'), findsOneWidget);

    // 2. Tap Day 1 card
    await tester.tap(find.text('AI Web Summarizer'));
    await tester.pumpAndSettle();
    expect(find.text('Website URL'), findsOneWidget);

    // 3. Navigate back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. Tap Day 2 card
    await tester.tap(find.text('Smart Shop Assistant'));
    await tester.pumpAndSettle();
    expect(find.text('🛍️ Smart Shop Assistant'), findsOneWidget);
    expect(find.text('How much is the bag?'), findsOneWidget);
  });
}
