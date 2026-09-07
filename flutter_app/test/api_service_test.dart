import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/api_service.dart';

void main() {
  group('SummarizeResult', () {
    test('correctly decodes valid JSON response from Python backend', () {
      const sampleJson = '''
      {
        "success": true,
        "url": "https://example.com",
        "summary": "### Key Points\\n- Point 1\\n- Point 2"
      }
      ''';

      final decoded = jsonDecode(sampleJson) as Map<String, dynamic>;
      final result = SummarizeResult.fromJson(decoded);

      expect(result.success, isTrue);
      expect(result.url, 'https://example.com');
      expect(result.summary, '### Key Points\n- Point 1\n- Point 2');
    });

    test('handles fallback defaults for missing fields', () {
      final decoded = <String, dynamic>{};
      final result = SummarizeResult.fromJson(decoded);

      expect(result.success, isTrue);
      expect(result.url, '');
      expect(result.summary, '');
    });
  });
}
