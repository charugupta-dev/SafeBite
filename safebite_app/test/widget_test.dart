import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safebite_app/main.dart';

void main() {
  testWidgets('Safebite App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SafebiteApp()));
    await tester.pumpAndSettle();

    expect(find.text('Safebite'), findsOneWidget);
    expect(find.text('Pediatric Food Safety Scanner'), findsOneWidget);
    expect(find.text('Scan Selected Packaging Label'), findsOneWidget);
  });
}
