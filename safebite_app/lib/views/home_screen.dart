import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _foodController = TextEditingController();

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  void _onAnalyze() {
    final food = _foodController.text;
    ref.read(homeViewModelProvider.notifier).checkFood(food);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Safebite',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Check Food Safety',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a food item and select who is eating it.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Target Selection (Profile)
              DropdownButtonFormField<String>(
                initialValue: scanState.selectedTarget,
                decoration: InputDecoration(
                  labelText: 'Who is eating?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'baby', child: Text('👶 Baby (8 months)')),
                  DropdownMenuItem(value: 'me', child: Text('👩 Me (Lactose Intolerant)')),
                  DropdownMenuItem(value: 'parent', child: Text('👴 Parent (Diabetic)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    viewModel.setTarget(value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Food Input Field
              TextField(
                controller: _foodController,
                decoration: InputDecoration(
                  labelText: 'Food item (e.g. banana, chocolate)',
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
                onSubmitted: (_) => _onAnalyze(),
              ),
              const SizedBox(height: 24),

              // Action Button
              ElevatedButton(
                onPressed: scanState.isLoading ? null : _onAnalyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        'Analyze Safety',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 32),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
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

              // Verdict Result Feedback
              if (scanState.hasResult)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
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
                            'AI VERDICT',
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
                                '${scanState.result!.toolsUsed.length} tools called',
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
                      Text(
                        scanState.result!.verdict,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
