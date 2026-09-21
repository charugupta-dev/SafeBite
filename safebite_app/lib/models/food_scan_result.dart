class FoodScanResult {
  final bool success;
  final String verdict;
  final List<String> toolsUsed;

  const FoodScanResult({
    required this.success,
    required this.verdict,
    required this.toolsUsed,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    return FoodScanResult(
      success: json['success'] as bool? ?? true,
      verdict: json['verdict'] as String? ?? '',
      toolsUsed: (json['tools_used'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
