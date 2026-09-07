import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SummarizeResult {
  final bool success;
  final String url;
  final String summary;

  SummarizeResult({
    required this.success,
    required this.url,
    required this.summary,
  });

  factory SummarizeResult.fromJson(Map<String, dynamic> json) {
    return SummarizeResult(
      success: json['success'] as bool? ?? true,
      url: json['url'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class ApiService {
  // iOS Simulator maps directly to Mac localhost (127.0.0.1)
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  final String baseUrl;
  final http.Client client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<SummarizeResult> summarizeUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      throw Exception('Please enter a website URL');
    }

    final endpoint = Uri.parse('$baseUrl/summarize');

    try {
      final response = await client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': cleanUrl}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SummarizeResult.fromJson(data);
      } else {
        String errorMessage = 'Server error (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception(
        'Cannot reach Python backend server at $baseUrl.\n\nPlease start the server in terminal:\ncd /Users/charu/Desktop/AIEngineeringLearning/python_files\nuvicorn api:app --reload --host 127.0.0.1 --port 8000',
      );
    } on http.ClientException {
      throw Exception(
        'Connection failed. Please ensure the Python API server is running on port 8000.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
