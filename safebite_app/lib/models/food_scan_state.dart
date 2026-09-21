import 'food_scan_result.dart';

enum ScanStatus { initial, loading, success, error }

class FoodScanState {
  final String selectedTarget;
  final ScanStatus status;
  final FoodScanResult? result;
  final String? errorMessage;

  const FoodScanState({
    this.selectedTarget = 'baby',
    this.status = ScanStatus.initial,
    this.result,
    this.errorMessage,
  });

  bool get isLoading => status == ScanStatus.loading;
  bool get hasError => status == ScanStatus.error && errorMessage != null;
  bool get hasResult => status == ScanStatus.success && result != null;

  FoodScanState copyWith({
    String? selectedTarget,
    ScanStatus? status,
    FoodScanResult? result,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return FoodScanState(
      selectedTarget: selectedTarget ?? this.selectedTarget,
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
