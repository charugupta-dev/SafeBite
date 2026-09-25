import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';
import 'ingredient_review_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _foodController = TextEditingController();
  String _selectedSampleImage = 'assets/images/sample_label.png';

  @override
  void initState() {
    super.initState();
    _foodController.addListener(() {
      final state = ref.read(homeViewModelProvider);
      if (state.hasResult || state.hasError) {
        ref.read(homeViewModelProvider.notifier).clearResult();
      }
    });
  }

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  void _onAnalyzeManual() {
    final food = _foodController.text.trim();
    if (food.isNotEmpty) {
      ref.read(homeViewModelProvider.notifier).checkFood(food);
    }
  }

  Future<void> _onScanSampleImage() async {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    viewModel.clearResult();
    final ingredients = await viewModel.processAssetSampleImage(_selectedSampleImage);
    if (mounted) {
      if (ingredients.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const IngredientReviewScreen(),
          ),
        );
        // Clean result when returning to HomeScreen for a new check
        viewModel.clearResult();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ingredients detected. Please try another sample.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Row(
                children: [
                  Icon(Icons.shield, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Safebite',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: const Color(0xFFE2E8F0), height: 1),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pediatric Food Safety Scanner',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profile Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WHO IS EATING?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: scanState.selectedTarget,
                      decoration: InputDecoration(
                        labelText: 'Select Profile',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'baby',
                          child: Text('👶 Baby / Toddler'),
                        ),
                        DropdownMenuItem(
                          value: 'me',
                          child: Text('👩 Me (Lactose Intolerant)'),
                        ),
                        DropdownMenuItem(
                          value: 'parent',
                          child: Text('👴 Parent (Diabetic)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) viewModel.setTarget(value);
                      },
                    ),
                    if (scanState.selectedTarget == 'baby') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: scanState.ageRange,
                        decoration: InputDecoration(
                          labelText: 'Baby Age Range',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '6 - 12 months',
                            child: Text('6 - 12 months (Starting solids)', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: '12 - 28 months',
                            child: Text('12 - 28 months (Toddler)', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: '28 - 48 months',
                            child: Text('28 - 48 months (Young child: 2.5 - 4 yrs)', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: '48+ months',
                            child: Text('48+ months (4+ years)', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            int representativeMonths = 8;
                            if (val == '12 - 28 months') representativeMonths = 18;
                            if (val == '28 - 48 months') representativeMonths = 36;
                            if (val == '48+ months') representativeMonths = 48;
                            viewModel.setAgeRange(val, representativeMonths);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // OCR Packaging Scan Card (Option A)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFF059669)),
                        SizedBox(width: 8),
                        Text(
                          'On-Device Label OCR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan ingredients via local Google ML Kit. You can review and edit detected chips before running safety analysis.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF047857)),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedSampleImage,
                      decoration: InputDecoration(
                        labelText: 'Sample Packaging Image',
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'assets/images/sample_label.png',
                          child: Text('🍏 Toddler Bites (Honey, Yellow 5)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'assets/images/Ingredients1.png',
                          child: Text('🥣 Bran Flakes (Ingredients1.png)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'assets/images/Ingredients2.png',
                          child: Text('🍫 Cadbury Chocolate (Ingredients2.png)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSampleImage = val);
                          viewModel.clearResult();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: scanState.isOcrProcessing
                            ? null
                            : _onScanSampleImage,
                        icon: scanState.isOcrProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.document_scanner),
                        label: Text(
                          scanState.isOcrProcessing
                              ? 'Recognizing Text...'
                              : 'Scan Selected Packaging Label',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // OR divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CHECK MANUALLY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                ],
              ),

              const SizedBox(height: 18),

              // Manual text input
              TextField(
                controller: _foodController,
                decoration: InputDecoration(
                  labelText: 'Food item or ingredients (e.g. Mashed banana, Honey)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _foodController.clear(),
                  ),
                ),
                onSubmitted: (_) => _onAnalyzeManual(),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: scanState.isLoading ? null : _onAnalyzeManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: scanState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analyze Manually',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Error Feedback
              if (scanState.hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scanState.errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Manual Verdict Result Feedback
              if (scanState.hasResult)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SAFETY REPORT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (scanState.result!.toolsUsed.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${scanState.result!.toolsUsed.length} tools',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MarkdownBody(
                        data: scanState.result!.verdict,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF1E293B),
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
