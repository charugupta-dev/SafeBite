import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_scan_state.dart';
import '../services/api_service.dart';
import '../services/ocr_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());

final homeViewModelProvider = NotifierProvider<HomeViewModel, FoodScanState>(
  HomeViewModel.new,
);

class HomeViewModel extends Notifier<FoodScanState> {
  @override
  FoodScanState build() {
    return const FoodScanState();
  }

  void setTarget(String target) {
    state = state.copyWith(
      selectedTarget: target,
      clearResult: true,
      clearError: true,
    );
  }

  void setAgeMonths(int months) {
    state = state.copyWith(
      ageMonths: months,
      clearResult: true,
      clearError: true,
    );
  }

  void setAgeRange(String range, int representativeMonths) {
    state = state.copyWith(
      ageRange: range,
      ageMonths: representativeMonths,
      clearResult: true,
      clearError: true,
    );
  }

  void setScannedIngredients(List<String> ingredients) {
    state = state.copyWith(
      scannedIngredients: ingredients,
      clearResult: true,
      clearError: true,
    );
  }

  void addIngredient(String ingredient) {
    final clean = ingredient.trim();
    if (clean.isEmpty) return;
    final updated = List<String>.from(state.scannedIngredients);
    if (!updated.contains(clean)) {
      updated.add(clean);
      state = state.copyWith(scannedIngredients: updated, clearResult: true);
    }
  }

  void removeIngredient(int index) {
    final updated = List<String>.from(state.scannedIngredients);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(scannedIngredients: updated, clearResult: true);
    }
  }

  void clearResult() {
    state = state.copyWith(
      status: ScanStatus.initial,
      clearResult: true,
      clearError: true,
    );
  }

  Future<List<String>> processAssetSampleImage(String assetPath) async {
    state = state.copyWith(
      isOcrProcessing: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final ocrService = ref.read(ocrServiceProvider);
      final tempFilePath = await ocrService.prepareAssetForOcr(assetPath);
      final rawText = await ocrService.recognizeTextFromPath(tempFilePath);
      final ingredients = ocrService.parseIngredients(rawText);
      state = state.copyWith(
        isOcrProcessing: false,
        scannedIngredients: ingredients,
        clearResult: true,
      );
      return ingredients;
    } catch (e) {
      state = state.copyWith(
        isOcrProcessing: false,
        errorMessage: 'OCR Failed: $e',
        clearResult: true,
      );
      return [];
    }
  }

  Future<void> checkFood([String? customFoodName]) async {
    final foodToCheck = customFoodName?.trim().isNotEmpty == true
        ? customFoodName!.trim()
        : state.scannedIngredients.join(', ');

    if (foodToCheck.isEmpty) return;

    state = state.copyWith(
      status: ScanStatus.loading,
      clearError: true,
      clearResult: true,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.checkFood(
        foodToCheck,
        state.selectedTarget,
        ageMonths: state.ageMonths,
        ageRange: state.ageRange,
      );
      state = state.copyWith(status: ScanStatus.success, result: result);
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
