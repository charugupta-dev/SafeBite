import 'package:flutter_test/flutter_test.dart';
import 'package:safebite_app/services/ocr_service.dart';

void main() {
  test('OcrService parses raw ingredient label text accurately', () {
    final ocr = OcrService();
    const rawSample = '''
ORGANIC TODDLER SNACK BITES
INGREDIENTS:
Organic Apples, Raw Honey (3%), Cane Sugar, Wheat Flour, Yellow 5 (Tartrazine), Natural Flavor.
''';

    final ingredients = ocr.parseIngredients(rawSample);

    expect(ingredients, contains('Organic Apples'));
    expect(ingredients, contains('Raw Honey'));
    expect(ingredients, contains('Cane Sugar'));
    expect(ingredients, contains('Wheat Flour'));
    expect(ingredients, contains('Yellow 5 (Tartrazine)'));
    expect(ingredients, contains('Natural Flavor'));
    expect(ingredients.length, 6);
  });

  test('OcrService parses Ingredients1.png (Cereal) packaging text', () {
    final ocr = OcrService();
    const rawCereal = '''
Ingredients
Wholewheat (81%), Wheat Bran, Sugar,
Barley Malt Extract, Salt, Niacin, Iron,
Pantothenic Acid, Thiamin, Vitamin B6,
Riboflavin, Folic Acid, Vitamin D,
Vitamin B12.
Allergy Advice: For allergens, including cereals
containing gluten, see highlighted ingredients.
May contain traces of Nuts.
Nutrition Information
''';
    final ingredients = ocr.parseIngredients(rawCereal);
    expect(ingredients, contains('Wholewheat'));
    expect(ingredients, contains('Wheat Bran'));
    expect(ingredients, contains('Sugar'));
    expect(ingredients, contains('Barley Malt Extract'));
    expect(ingredients, contains('Salt'));
    expect(ingredients, contains('Iron'));
    // Should NOT contain allergy advice or nutrition text
    expect(ingredients.any((i) => i.contains('Allergy Advice')), isFalse);
    expect(ingredients.any((i) => i.contains('Nutrition')), isFalse);
  });

  test('OcrService parses Ingredients2.png (Chocolate) packaging text', () {
    final ocr = OcrService();
    const rawChocolate = '''
INGREDIENTS
Milk Chocolate. Ingredients: Sugar, Milk
Solids (23%*), Cocoa Butter, Cocoa Solids,
Fractionated Fat, Emulsifiers (442, 476),
Flavours (Natural, Nature Identical and
Artificial (Vanilla) Flavouring Substances).
CONTAINS COCOA BUTTER EQUIVALENT
IN ADDITION TO COCOA BUTTER.
Allergen Information: Contains Milk, Soy.
May Contain Tree Nuts, Wheat, Barley.
''';
    final ingredients = ocr.parseIngredients(rawChocolate);
    expect(ingredients, contains('Sugar'));
    expect(ingredients, contains('Milk Solids'));
    expect(ingredients, contains('Cocoa Butter'));
    expect(ingredients, contains('Cocoa Solids'));
    expect(ingredients, contains('Fractionated Fat'));
    expect(ingredients.any((i) => i.contains('Allergen Information')), isFalse);
  });
}
