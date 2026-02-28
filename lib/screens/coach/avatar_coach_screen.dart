import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/parot_mascot.dart';
import '../../services/coach_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_background.dart';

class AvatarCoachScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AvatarCoachScreen({super.key, this.onBack});

  @override
  State<AvatarCoachScreen> createState() => _AvatarCoachScreenState();
}

class _AvatarCoachScreenState extends State<AvatarCoachScreen>
    with SingleTickerProviderStateMixin {
  String _statusText = "Tap the orb to start";
  String _transcriptText = "";
  Map<String, dynamic>? _lastFeedback; // {score, tip, reply}
  bool _isListening = false;
  bool _isThinking = false;

  double _avatarMood = 50.0; // 0-100
  final FocusNode _noteFocusNode = FocusNode();
  bool _isInputActive = false;

  // Real app: Ideally fetch from current "Active Scenario"
  final String _currentScenario = "Salary Negotiation";
  final String _persona = "Professional HR Manager";

  @override
  void initState() {
    super.initState();
    _noteFocusNode.addListener(() {
      setState(() {
        _isInputActive = _noteFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    final coachService = context.read<CoachService>();
    final aiService = context.read<AiService>();

    if (_isListening) {
      // STOP
      await coachService.stopListening();
      setState(() {
        _isListening = false;
        _isThinking = true;
        _statusText = "Analyzing your tone...";
      });

      // Analyze & Reply
      try {
        // 1. Get Feedback
        final analysis = await aiService.analyzeUserMessage(
          message: _transcriptText,
          context: _currentScenario,
        );

        // 2. Get AI Reply
        final replyData = await aiService.generateReply(
          prompt: _transcriptText,
          context: _currentScenario,
          persona: _persona,
        );

        final reply = replyData['reply'] ?? "I didn't catch that.";
        final score = analysis['score'];
        final tip = analysis['feedback'] ?? "Keep practicing!";

        if (mounted) {
          setState(() {
            _isThinking = false;
            _statusText = "AI Response";
            _lastFeedback = {'reply': reply, 'score': score, 'tip': tip};
          });
        }

        // Voice Output
        await coachService.speak("Here's a quick tip: $tip");
        await Future.delayed(const Duration(seconds: 4));
        await coachService.speak(reply);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isThinking = false;
            _statusText = "Error: $e";
          });
        }
      }
    } else {
      // START
      setState(() {
        _isListening = true;
        _statusText = "Listening...";
        _transcriptText = "";
        _lastFeedback = null;
      });

      await coachService.stopSpeaking();
      await coachService.startListening(
        onResult: (text) {
          setState(() {
            _transcriptText = text;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PremiumBackground(
        child: Stack(
          children: [
            // Old background removed
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header (Scenario Context)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Changed to spaceBetween
                      children: [
                        // Placeholder to balance the row (or back button if needed, but close is better for modal feel)
                        const SizedBox(width: 40),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.topic_outlined,
                                size: 14,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentScenario,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // CLOSE BUTTON
                        IconButton(
                          onPressed: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            }
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.black54,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // MAIN VISUALIZER (The Mascot)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ParotMascot(
                        state: _isThinking
                            ? ParotState.thinking
                            : _isListening
                            ? ParotState.listening
                            : ParotMascot.fromMood(
                                moodValue: _avatarMood,
                              ).state,
                        size: _isInputActive ? 150 : 320,
                      ),
                    ),
                  ),

                  if (!_isInputActive) ...[
                    const SizedBox(height: 20),
                    // Mood Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.black87,
                          inactiveTrackColor: Colors.black12,
                          thumbColor: Colors.black,
                          overlayColor: Colors.black12,
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8.0,
                          ),
                        ),
                        child: Slider(
                          value: _avatarMood,
                          min: 0,
                          max: 100,
                          onChanged: (val) {
                            setState(() {
                              _avatarMood = val;
                            });
                          },
                          onChangeEnd: (val) {
                            // Logic removed with EmpathyAvatar
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Status Text
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate(target: _isThinking ? 1 : 0).shimmer(),

                  const SizedBox(height: 16),

                  // Real-time Transcript
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _transcriptText.isEmpty && !_isListening
                          ? "Tap the orb to start speaking."
                          : _transcriptText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // AI Feedback Card (Only if present)
                  if (_lastFeedback != null)
                    _buildFeedbackCard(_lastFeedback!)
                        .animate()
                        .slideY(begin: 1, curve: Curves.easeOutBack)
                        .fadeIn(),

                  // Adjust for bottom safe area
                  const SizedBox(height: 20),

                  // Add Note Input
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: TextField(
                      focusNode: _noteFocusNode,
                      decoration: InputDecoration(
                        hintText: "Add Note...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "SCORE: ${data['score']}/10",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFEAB308),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['tip'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['reply'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
