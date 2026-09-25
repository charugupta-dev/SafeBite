import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/food_scan_result.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  final String baseUrl;
  final http.Client client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<FoodScanResult> checkFood(
    String food,
    String target, {
    int ageMonths = 8,
    String? ageRange,
  }) async {
    final cleanFood = food.trim();
    if (cleanFood.isEmpty) throw Exception('Please enter a food item');

    final endpoint = Uri.parse('$baseUrl/check-food');

    try {
      final payload = <String, dynamic>{
        'food': cleanFood,
        'target': target,
        'age_months': ageMonths,
      };
      if (ageRange != null && ageRange.isNotEmpty) {
        payload['age_range'] = ageRange;
      }

      final response = await client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
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
      throw Exception('Cannot reach Python backend. Please ensure the server is running on port 8000.');
    } on http.ClientException {
      throw Exception('Connection failed. Please ensure the Python API server is running.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
