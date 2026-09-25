import 'food_scan_result.dart';

enum ScanStatus { initial, loading, success, error }

class FoodScanState {
  final String selectedTarget;
  final int ageMonths;
  final String ageRange;
  final ScanStatus status;
  final FoodScanResult? result;
  final String? errorMessage;
  final List<String> scannedIngredients;
  final bool isOcrProcessing;

  const FoodScanState({
    this.selectedTarget = 'baby',
    this.ageMonths = 8,
    this.ageRange = '6 - 12 months',
    this.status = ScanStatus.initial,
    this.result,
    this.errorMessage,
    this.scannedIngredients = const [],
    this.isOcrProcessing = false,
  });

  bool get isLoading => status == ScanStatus.loading;
  bool get hasError => status == ScanStatus.error && errorMessage != null;
  bool get hasResult => status == ScanStatus.success && result != null;

  FoodScanState copyWith({
    String? selectedTarget,
    int? ageMonths,
    String? ageRange,
    ScanStatus? status,
    FoodScanResult? result,
    String? errorMessage,
    List<String>? scannedIngredients,
    bool? isOcrProcessing,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return FoodScanState(
      selectedTarget: selectedTarget ?? this.selectedTarget,
      ageMonths: ageMonths ?? this.ageMonths,
      ageRange: ageRange ?? this.ageRange,
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      scannedIngredients: scannedIngredients ?? this.scannedIngredients,
      isOcrProcessing: isOcrProcessing ?? this.isOcrProcessing,
    );
  }
}
