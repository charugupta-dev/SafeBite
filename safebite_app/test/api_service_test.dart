import 'package:flutter_test/flutter_test.dart';
import 'package:safebite_app/services/api_service.dart';

void main() {
  test('ApiService checks food safety with backend for 8-month baby', () async {
    final api = ApiService(baseUrl: 'http://127.0.0.1:8000');
    final result = await api.checkFood(
      'Organic Apples, Raw Honey, Cane Sugar, Wheat Flour, Yellow 5 (Tartrazine), Natural Flavor',
      'baby',
      ageMonths: 8,
    );

    expect(result.verdict, isNotEmpty);
    print('\n================ VERDICT OUTPUT ================\n${result.verdict}\n================================================\n');
    expect(result.verdict, contains('UNSAFE'));
    // Should flag Honey (< 12 months) and Cane Sugar (< 24 months)
    expect(result.verdict.toLowerCase(), contains('honey'));
    expect(result.verdict.toLowerCase(), contains('sugar'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('ApiService checks Ingredients1 (Cereal) safety for 8-month baby', () async {
    final api = ApiService(baseUrl: 'http://127.0.0.1:8000');
    final result = await api.checkFood(
      'Wholewheat, Wheat Bran, Sugar, Barley Malt Extract, Salt, Iron, Thiamin, Vitamin B6, Vitamin D',
      'baby',
      ageMonths: 8,
    );

    expect(result.verdict, isNotEmpty);
    print('\n================ CEREAL VERDICT OUTPUT ================\n${result.verdict}\n=======================================================\n');
    // Flags added sugar (< 24 months) and high sodium/salt
    expect(result.verdict, contains('UNSAFE'));
    expect(result.verdict.toLowerCase(), contains('sugar'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('ApiService checks Ingredients2 (Chocolate) safety for 8-month baby', () async {
    final api = ApiService(baseUrl: 'http://127.0.0.1:8000');
    final result = await api.checkFood(
      'Sugar, Milk Solids, Cocoa Butter, Cocoa Solids, Fractionated Fat, Emulsifiers (442, 476)',
      'baby',
      ageMonths: 8,
    );

    expect(result.verdict, isNotEmpty);
    print('\n================ CHOCOLATE VERDICT OUTPUT ================\n${result.verdict}\n==========================================================\n');
    // Flags Sugar (< 24 months) and Cocoa/Caffeine stimulants (< 24 months)
    expect(result.verdict, contains('UNSAFE'));
    expect(result.verdict.toLowerCase(), contains('sugar'));
  });
}
