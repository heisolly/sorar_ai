import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionFlowScreen extends StatelessWidget {
  const QuestionFlowScreen({super.key});

  final List<Map<String, dynamic>> scenarios = const [
    {
      "title": "Ask for a Raise",
      "desc": "Negotiate with a busy boss.",
      "level": "Hard",
      "color": Color(0xFF8B5CF6),
      "icon": Icons.monetization_on_outlined,
    },
    {
      "title": "Cancel Plans",
      "desc": "Tell a friend you can't make it.",
      "level": "Easy",
      "color": Color(0xFFF43F5E),
      "icon": Icons.event_busy_rounded,
    },
    {
      "title": "Coffee Shop Approach",
      "desc": "Start a convo with a stranger.",
      "level": "Medium",
      "color": Color(0xFFEAB308),
      "icon": Icons.coffee_rounded,
    },
    {
      "title": "Critique a Coworker",
      "desc": "Give feedback without being rude.",
      "level": "Hard",
      "color": Color(0xFF3B82F6),
      "icon": Icons.work_outline_rounded,
    },
    {
      "title": "Breakup Conversation",
      "desc": "End a relationship respectfully.",
      "level": "Expert",
      "color": Color(0xFF64748B),
      "icon": Icons.heart_broken_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F8), // Soft Pinkish White
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Scenario Library",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(Icons.search, size: 28, color: Color(0xFF0F172A)),
                ],
              ),
            ),

            // --- FILTERS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip("All Scenarios", true),
                  const SizedBox(width: 12),
                  _buildFilterChip("Work", false),
                  const SizedBox(width: 12),
                  _buildFilterChip("Social", false),
                  const SizedBox(width: 12),
                  _buildFilterChip("Dating", false),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- LIST ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: scenarios.length + 1, // +1 for spacer
                itemBuilder: (context, index) {
                  if (index == scenarios.length) {
                    return const SizedBox(height: 110); // Bottom nav spacing
                  }

                  final scenario = scenarios[index];
                  return _buildScenarioCard(scenario);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (scenario['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(scenario['icon'], color: scenario['color'], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario['title'],
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scenario['desc'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scenario['level'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
