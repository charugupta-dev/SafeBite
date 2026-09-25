import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static const MethodChannel _channel = MethodChannel('safebite/ocr');

  /// Extracts text from a local filesystem image path using native on-device Apple Vision OCR.
  Future<String> recognizeTextFromPath(String imagePath) async {
    try {
      final String? result = await _channel.invokeMethod<String>(
        'recognizeText',
        {'imagePath': imagePath},
      );
      return result ?? '';
    } catch (e) {
      print('OCR recognition error: $e');
      return '';
    }
  }

  /// Copies a bundled Flutter asset image into a temp file path so OCR can process it.
  Future<String> prepareAssetForOcr(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_ocr_sample.png');
    await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      flush: true,
    );
    return tempFile.path;
  }

  /// Parses raw OCR packaging text into individual, clean ingredient tokens.
  List<String> parseIngredients(String rawText) {
    if (rawText.trim().isEmpty) return [];

    String cleaned = rawText;

    // Discard sections following allergy advice, allergen information, nutrition facts, or trace warnings
    final cutoffRegex = RegExp(
      r'(allergy advice|allergen information|nutrition information|nutrition facts|may contain|contains cocoa butter equivalent)',
      caseSensitive: false,
    );
    final cutoffMatch = cutoffRegex.firstMatch(cleaned);
    if (cutoffMatch != null) {
      cleaned = cleaned.substring(0, cutoffMatch.start);
    }

    // If "Ingredients:" or "Ingredients" is present, take text following it
    final ingMatches = RegExp(
      r'ingredients[\s:]*',
      caseSensitive: false,
    ).allMatches(cleaned);
    if (ingMatches.isNotEmpty) {
      // Use the last "Ingredients:" occurrence (e.g. past "Milk Chocolate. Ingredients:")
      cleaned = cleaned.substring(ingMatches.last.end);
    }

    // Remove percentages like (81%), (23%*), 3%, etc.
    cleaned = cleaned.replaceAll(RegExp(r'\(\s*\d+(\.\d+)?%?\*?\s*\)'), '');

    // Normalize newlines to spaces so wrapped words stay together (e.g. Milk\nSolids -> Milk Solids)
    cleaned = cleaned.replaceAll(RegExp(r'\s*\n\s*'), ' ');

    // Split on commas, semicolons, or bullets OUTSIDE parentheses
    final rawTokens = cleaned.split(RegExp(r'[,;•](?![^()]*\))'));
    final List<String> result = [];

    for (var token in rawTokens) {
      var trimmed = token.trim().replaceAll(RegExp(r'[\.\s]+$'), '').trim();

      if (trimmed.length > 1 &&
          !trimmed.toUpperCase().startsWith('CONTAINS COCOA') &&
          !trimmed.toUpperCase().contains('ORGANIC TODDLER') &&
          !trimmed.toUpperCase().contains('NUTRITION')) {
        if (!result.contains(trimmed)) {
          result.add(trimmed);
        }
      }
    }

    return result;
  }
}
