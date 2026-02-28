import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/question_card.dart';

class QuestionCardWidget extends StatefulWidget {
  final QuestionCard card;
  final Function(int) onOptionSelected;
  final VoidCallback onNext;

  const QuestionCardWidget({
    super.key,
    required this.card,
    required this.onOptionSelected,
    required this.onNext,
  });

  @override
  State<QuestionCardWidget> createState() => _QuestionCardWidgetState();
}

class _QuestionCardWidgetState extends State<QuestionCardWidget> {
  final FlutterTts flutterTts = FlutterTts();
  int? _selectedOptionIndex;
  bool _showFeedback = false;

  // Colors for specific option vibes (mapped by index for MVP)
  // 0: Funny/Playful (Yellow), 1: Cool/Smooth (Teal), 2: Deep/Respectful (Purple), 3: Safe/Neutral (Gray)
  final List<Color> _optionColors = [
    const Color(0xFFFDD835), // Yellow
    const Color(0xFF00BFA5), // Teal
    const Color(0xFF7C4DFF), // Purple
    const Color(0xFF9E9E9E), // Gray
  ];

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakScenario() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(widget.card.scenario);
  }

  void _handleSelection(int index) {
    if (_showFeedback) return;
    setState(() {
      _selectedOptionIndex = index;
      _showFeedback = true;
    });
    widget.onOptionSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          // Background Gradient subtle
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Badge + Stars)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          widget.card.category,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getCategoryColor(
                            widget.card.category,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        widget.card.category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: _getCategoryColor(widget.card.category),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(3, (index) {
                        // Simple difficulty mock: "Hard" -> 3 stars
                        int stars = widget.card.difficulty == 'Hard'
                            ? 3
                            : (widget.card.difficulty == 'Medium' ? 2 : 1);
                        return Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Scenario Text
                Text(
                  widget.card.scenario,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 16),

                // Voice Prompt Button
                Center(
                  child: GestureDetector(
                    onTap: _speakScenario,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Options or Feedback
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showFeedback
                      ? _buildFeedbackView()
                      : Column(
                          key: const ValueKey('options'),
                          children: [
                            for (int i = 0; i < widget.card.options.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child:
                                    _buildOptionBubble(
                                          i,
                                          widget.card.options[i],
                                        )
                                        .animate()
                                        .fadeIn(delay: (i * 100).ms)
                                        .slideY(begin: 0.1),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Rizz')) return Colors.pinkAccent;
    if (category.contains('Family')) return Colors.blueAccent;
    return Colors.purpleAccent;
  }

  Widget _buildOptionBubble(int index, String text) {
    // Determine color based on index or logic (MVP: Index mapping)
    // 0: Fun, 1: Cool, 2: Deep, 3: Weak
    // If fewer than 4 options, fallback to white/grey
    Color baseColor = (index < 4) ? _optionColors[index] : Colors.white;

    return InkWell(
      onTap: () => _handleSelection(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Small colored dot or icon
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackView() {
    final isCorrect = _selectedOptionIndex == widget.card.bestOptionIndex;
    return Column(
      key: const ValueKey('feedback'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating & Indicator
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '8/10 — Strong Aura!' : 'Weak Choice...',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  isCorrect ? '+10 Points' : 'Try Again for Points',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COACH BREAKDOWN',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.explanation,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _speakScenario,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Replay Voice',
                  style: GoogleFonts.outfit(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Next Card',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
