import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/scenario_card.dart';
import '../speech/speech_session_screen.dart';

class ScenarioCardDetailScreen extends StatefulWidget {
  final ScenarioCard scenarioCard;

  const ScenarioCardDetailScreen({super.key, required this.scenarioCard});

  @override
  State<ScenarioCardDetailScreen> createState() =>
      _ScenarioCardDetailScreenState();
}

class _ScenarioCardDetailScreenState extends State<ScenarioCardDetailScreen> {
  ResponseOption? _selectedOption;
  bool _showFeedback = false;

  void _selectOption(ResponseOption option) {
    setState(() {
      _selectedOption = option;
      _showFeedback = false;
    });

    // Show feedback after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showFeedback = true;
        });
      }
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFF43F5E); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAE4D7), // AppColors.primaryBackground
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2B2521,
                            ).withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF2B2521),
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Optional: Difficulty Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      widget.scenarioCard.difficulty.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A4338),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Situation Card (Immersive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F2EE), // Warm neutral
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2B2521,
                            ).withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Minimal Accent Line instead of big Label
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC6A27E), // Muted bronze
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.scenarioCard.situation,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2B2521),
                              fontSize: 18,
                              fontWeight: FontWeight
                                  .w500, // Slightly lighter weight for narrative feel
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Context Tags
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildContextTag("Environment: Casual"),
                              _buildContextTag("Risk Level: Low"),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05),

                    const SizedBox(height: 32),

                    // Prompt Title
                    Text(
                      'What do you do?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B2521),
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 4),

                    Text(
                      'Tone matters more than words.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF8A6E61),
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    // Response Options
                    ...widget.scenarioCard.options.asMap().entries.map((entry) {
                      final option = entry.value;
                      final isSelected = _selectedOption?.id == option.id;

                      // Aura color logic for visual variety (simulated)
                      final auraColors = [
                        const Color(0xFFC6A27E), // Bronze
                        const Color(0xFF7FAFC8), // Blue
                        const Color(0xFFD08A6A), // Terracotta
                      ];
                      final accentColor =
                          auraColors[entry.key % auraColors.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child:
                            GestureDetector(
                                  onTap: () => _selectOption(option),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2B2521)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? null
                                          : Border(
                                              left: BorderSide(
                                                color: accentColor,
                                                width: 4,
                                              ),
                                            ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF2B2521,
                                                ).withValues(alpha: 0.3)
                                              : Colors.black.withValues(
                                                  alpha: 0.03,
                                                ),
                                          blurRadius: isSelected ? 16 : 8,
                                          offset: Offset(0, isSelected ? 8 : 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.text,
                                          style: GoogleFonts.inter(
                                            color: isSelected
                                                ? const Color(0xFFFAE4D7)
                                                : const Color(0xFF2B2521),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            "You selected this response.",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                                .animate(delay: ((entry.key + 1) * 100).ms)
                                .fadeIn()
                                .slideX(begin: 0.05),
                      );
                    }),

                    // Feedback Section
                    if (_showFeedback && _selectedOption != null) ...[
                      const SizedBox(height: 32),
                      _buildFeedbackSection(),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2521).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: const Color(0xFF8A6E61),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      children: [
        Divider(color: const Color(0xFF2B2521).withValues(alpha: 0.1)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _getScoreColor(
                _selectedOption!.score,
              ).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B2521).withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Feedback",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A6E61),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedOption!.feedback,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF2B2521),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoreBadge(
                    _selectedOption!.score.toString(),
                    "Score",
                    _getScoreColor(_selectedOption!.score),
                  ),
                  const SizedBox(width: 24),
                  _buildScoreBadge(
                    _selectedOption!.toneAnalysis.tone,
                    "Tone",
                    const Color(0xFFC6A27E),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpeechSessionScreen(
                        scenarioTitle: widget.scenarioCard.situation
                            .split('.')
                            .first,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2521),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Start Practice Session",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildScoreBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF8A6E61),
          ),
        ),
      ],
    );
  }
}
