import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_scan_state.dart';
import '../services/api_service.dart';

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, FoodScanState>(HomeViewModel.new);

class HomeViewModel extends Notifier<FoodScanState> {
  @override
  FoodScanState build() {
    return const FoodScanState();
  }

  void setTarget(String target) {
    state = state.copyWith(selectedTarget: target);
  }

  Future<void> checkFood(String foodName) async {
    final cleanFood = foodName.trim();
    if (cleanFood.isEmpty) return;

    state = state.copyWith(
      status: ScanStatus.loading,
      clearError: true,
      clearResult: true,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.checkFood(cleanFood, state.selectedTarget);
      state = state.copyWith(
        status: ScanStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const FoodScanState();
  }
}
