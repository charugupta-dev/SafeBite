import 'package:flutter/material.dart';
import 'day1_summarizer_screen.dart';
import 'day2_shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            // Welcome Header
            const Text(
              'AI Engineering Projects',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Interactive mobile implementations of your AI engineering lessons.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Day 1 AI Web Summarizer
            _buildProjectCard(
              context,
              dayLabel: 'Day 1',
              title: 'AI Web Summarizer',
              badge: 'Scraping • LLM Prompting',
              badgeColor: const Color(0xFFE0E7FF),
              badgeTextColor: const Color(0xFF4338CA),
              description:
                  'Input any website URL to scrape its contents and generate a structured markdown summary.',
              icon: Icons.language,
              iconColor: const Color(0xFF6366F1),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Day1SummarizerScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // Card 2: Day 2 Smart Shop Assistant
            _buildProjectCard(
              context,
              dayLabel: 'Day 2',
              title: 'Smart Shop Assistant',
              badge: 'Tool Calling • Agents',
              badgeColor: const Color(0xFFFEF3C7),
              badgeTextColor: const Color(0xFFB45309),
              description:
                  'Chat with an autonomous AI shopping agent that executes get_price tools in real-time.',
              icon: Icons.storefront_outlined,
              iconColor: const Color(0xFFD97706),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Day2ShopScreen()),
                );
              },
            ),

            const SizedBox(height: 30),

            // Footer note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Both apps connect to your local Python FastAPI backend at http://127.0.0.1:8000',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required String dayLabel,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: iconColor,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
