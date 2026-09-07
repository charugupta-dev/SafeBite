import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('AI Lab app renders initial idle state smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AiLabApp());

    // Verify title and initial elements render
    expect(find.text('AI Lab'), findsOneWidget);
    expect(find.text('Website URL'), findsOneWidget);
    expect(find.text('Summarize Website with AI'), findsOneWidget);
    expect(find.text('How It Works'), findsOneWidget);
  });
}
