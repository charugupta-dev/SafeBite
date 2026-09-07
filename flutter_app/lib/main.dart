import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AiLabApp());
}

class AiLabApp extends StatelessWidget {
  const AiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
      ),
      home: const SummarizerHomeScreen(),
    );
  }
}

class SummarizerHomeScreen extends StatefulWidget {
  const SummarizerHomeScreen({super.key});


  @override
  State<SummarizerHomeScreen> createState() => _SummarizerHomeScreenState();
}

class _SummarizerHomeScreenState extends State<SummarizerHomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _summary;
  String? _errorMessage;
  String? _lastSummarizedUrl;

  final List<Map<String, String>> _sampleUrls = [
    {'title': '☕ Coffee Wiki', 'url': 'https://en.wikipedia.org/wiki/Coffee'},
    {'title': '🚀 Flutter', 'url': 'https://flutter.dev'},
    {'title': '🧠 OpenAI', 'url': 'https://openai.com/about'},
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSummarize() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a website URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summary = null;
      _lastSummarizedUrl = rawUrl;
    });

    try {
      final result = await _apiService.summarizeUrl(rawUrl);
      if (mounted) {
        setState(() {
          _summary = result.summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_summary != null) {
      Clipboard.setData(ClipboardData(text: _summary!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Summary copied to clipboard!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _urlController.clear();
      _summary = null;
      _errorMessage = null;
      _lastSummarizedUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text(
              'AI Lab',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_summary != null || _errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: _reset,
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Input Card
              _buildInputCard(),

              const SizedBox(height: 16),

              // 2. Action / Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 20),

              // 3. Scrollable Result / State Area
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_summary != null)
                _buildSuccessState()
              else
                _buildIdleState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Website URL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://en.wikipedia.org/wiki/Coffee',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF6366F1)),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handleSummarize(),
            ),
            const SizedBox(height: 12),
            // Quick samples
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Try sample:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                ..._sampleUrls.map(
                  (sample) => ActionChip(
                    label: Text(
                      sample['title']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFFEEF2FF),
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      _urlController.text = sample['url']!;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleSummarize,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      label: Text(
        _isLoading ? 'Summarizing...' : 'Summarize Website with AI',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF6366F1)),
            const SizedBox(height: 20),
            const Text(
              'Analyzing & Summarizing...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Scraping HTML via Python backend\n2. Extracting readable content\n3. Prompting AI model for summary',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      color: const Color(0xFFFFF1F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFECDD3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Color(0xFFE11D48)),
                SizedBox(width: 8),
                Text(
                  'Summarization Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE11D48),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF881337),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _handleSummarize,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE11D48),
                side: const BorderSide(color: Color(0xFFFDA4AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Generated via Python FastAPI & LLM',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy Summary',
                  color: const Color(0xFF6366F1),
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
            if (_lastSummarizedUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _lastSummarizedUrl!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                ),
              ),
            ],
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            MarkdownBody(
              data: _summary!,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: Color(0xFF1E293B),
                ),
                h1: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                h2: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                h3: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                listBullet: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 18.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                size: 32,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'How It Works',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter any website URL above and tap Summarize.\n\nFlutter sends the URL to your local Python backend (FastAPI), which scrapes the webpage and prompts the LLM to generate a clean summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
