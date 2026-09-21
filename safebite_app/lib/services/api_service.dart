import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SummarizeResult {
  final bool success;
  final String url;
  final String summary;

  SummarizeResult({required this.success, required this.url, required this.summary});
  factory SummarizeResult.fromJson(Map<String, dynamic> json) => SummarizeResult(
      success: json['success'] as bool? ?? true,
      url: json['url'] as String? ?? '',
      summary: json['summary'] as String? ?? '');
}

class AgentResult {
  final bool success;
  final String reply;
  final List<String> toolsUsed;

  AgentResult({required this.success, required this.reply, required this.toolsUsed});
  factory AgentResult.fromJson(Map<String, dynamic> json) => AgentResult(
      success: json['success'] as bool? ?? true,
      reply: json['reply'] as String? ?? '',
      toolsUsed: (json['tools_used'] as List<dynamic>? ?? []).map((e) => e.toString()).toList());
}

class FoodScanResult {
  final bool success;
  final String verdict;
  final List<String> toolsUsed;

  FoodScanResult({required this.success, required this.verdict, required this.toolsUsed});
  
  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    return FoodScanResult(
      success: json['success'] as bool? ?? true,
      verdict: json['verdict'] as String? ?? '',
      toolsUsed: (json['tools_used'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class ApiService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  final String baseUrl;
  final http.Client client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<FoodScanResult> checkFood(String food, String target) async {
    final cleanFood = food.trim();
    if (cleanFood.isEmpty) throw Exception('Please enter a food item');

    final endpoint = Uri.parse('$baseUrl/check-food');

    try {
      final response = await client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'food': cleanFood, 'target': target}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FoodScanResult.fromJson(data);
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
      throw Exception('Cannot reach Python backend. Please start the FastAPI server.');
    } on http.ClientException {
      throw Exception('Connection failed. Please ensure the Python API server is running.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Keeping old methods so the code doesn't break
  Future<SummarizeResult> summarizeUrl(String url) async { return SummarizeResult(success: true, url: '', summary: ''); }
  Future<AgentResult> askAgent(String message) async { return AgentResult(success: true, reply: '', toolsUsed: []); }
}
