import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/guided_simulation.dart';
import '../../services/ai_service.dart';
import '../../widgets/parot_mascot.dart';
import '../../theme/app_theme.dart';

class GuidedSimulationScreen extends StatefulWidget {
  final GuidedSimulation simulation;

  const GuidedSimulationScreen({super.key, required this.simulation});

  @override
  State<GuidedSimulationScreen> createState() => _GuidedSimulationScreenState();
}

enum SimulationState { entry, question, input, summary }

class _GuidedSimulationScreenState extends State<GuidedSimulationScreen> {
  final AiService _aiService = AiService();
  SimulationState _currentState = SimulationState.entry;

  // Simulation State
  late List<SimulationBeat> _beats;
  int _currentBeatIndex = 0;
  final List<Map<String, String>> _history = []; // Role: content
  Map<String, dynamic>? _lastFeedback;

  // UI State
  final TextEditingController _inputController = TextEditingController();
  bool _isInputEmpty = true;
  bool _showAiAssist = false;
  bool _isLoading = false;

  // Colors
  final Color _bgPeach = const Color(0xFFFAE4D7);
  final Color _bgInput = const Color(0xFFF6F2EE);
  final Color _textDark = const Color(0xFF2B2521);
  final Color _accentBronze = const Color(0xFFC6A27E);

  @override
  void initState() {
    super.initState();
    // Initialize beats from the passed simulation
    _beats = List.from(widget.simulation.beats);
    _inputController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    setState(() {
      _isInputEmpty = _inputController.text.trim().isEmpty;
      if (!_isInputEmpty) {
        _showAiAssist = true;
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleEnhanceReply() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final enhanced = await _aiService.enhanceSimulationReply(
      originalText: _inputController.text,
      context: "${widget.simulation.context} (Beat ${_currentBeatIndex + 1})",
    );

    if (mounted) {
      setState(() {
        _inputController.text = enhanced;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGetSuggestions() async {
    setState(() => _isLoading = true);

    final suggestions = await _aiService.getSimulationSuggestions(
      context:
          "${widget.simulation.context} (Beat ${_currentBeatIndex + 1}) - ${_beats[_currentBeatIndex].question}",
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Suggestions from Coach",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...suggestions.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s['label'] ?? 'Option',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _accentBronze,
                  ),
                ),
                subtitle: Text(
                  s['text'] ?? '',
                  style: GoogleFonts.manrope(fontSize: 16, color: _textDark),
                ),
                onTap: () {
                  _inputController.text = s['text'] ?? '';
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lockInResponse() async {
    final userResponse = _inputController.text.trim();
    if (userResponse.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Add to history
    _history.add({
      'role': 'assistant',
      'content': _beats[_currentBeatIndex].question,
    }); // The situation/partner
    _history.add({'role': 'user', 'content': userResponse});

    // 2. Generate Next Beat & Feedback
    final result = await _aiService.generateNextBeat(
      currentBeatNumber: _currentBeatIndex + 1,
      totalBeats: 99, // Allow extended play
      context: widget.simulation.context,
      history: _history,
      userLastResponse: userResponse,
    );

    if (!mounted) return;

    setState(() {
      // Store feedback
      _lastFeedback = result['feedback'];

      // Update next beat (replace placeholder)
      final nextBeatData = result['next_beat'];
      if (nextBeatData != null && _currentBeatIndex + 1 < _beats.length) {
        // Replace the existing placeholder beat
        _beats[_currentBeatIndex + 1] = SimulationBeat(
          beatNumber: _currentBeatIndex + 2,
          title: nextBeatData['title'] ?? "Next Step",
          question: nextBeatData['question'] ?? "What do you do?",
          placeholder: nextBeatData['placeholder'] ?? "Type your action...",
        );
      } else if (nextBeatData != null) {
        // If we're at the end, add a new beat
        _beats.add(
          SimulationBeat(
            beatNumber: _currentBeatIndex + 2,
            title: nextBeatData['title'] ?? "Next Step",
            question: nextBeatData['question'] ?? "What do you do?",
            placeholder: nextBeatData['placeholder'] ?? "Type your action...",
          ),
        );
      }

      _currentState = SimulationState.question;
      _isLoading = false;

      // Auto-advance
      if (_currentBeatIndex < _beats.length - 1) {
        _currentBeatIndex++;
        _inputController.clear();
        _showAiAssist = false;
      } else {
        // Only show summary if explicitly ended (which we aren't doing yet, or if AI returns no next beat)
        // For now, if no next beat was added, we end.
        _currentState = SimulationState.summary;
      }
    });
  }

  void _startGame() {
    setState(() => _currentState = SimulationState.question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentState == SimulationState.input
          ? _bgInput
          : _bgPeach,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isLoading ? _buildLoadingView() : _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _textDark),
          const SizedBox(height: 16),
          Text(
            "Analyzing...",
            style: GoogleFonts.outfit(fontSize: 18, color: _textDark),
          ).animate().fadeIn().shimmer(duration: 2.seconds),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case SimulationState.entry:
        return _buildEntryView();
      case SimulationState.question:
        return _buildQuestionView();
      case SimulationState.input:
        return _buildInputView();

      case SimulationState.summary:
        return _buildSummaryView();
    }
  }

  // 1. Scenario Entry
  Widget _buildEntryView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _textDark),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const Spacer(),
          Text(
            widget.simulation.title,
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _textDark,
              height: 1.1,
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _accentBronze, width: 4)),
            ),
            child: Text(
              widget.simulation.context,
              style: GoogleFonts.manrope(
                fontSize: 18,
                color: _textDark.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.energyAccent, // Indigo
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Begin Scenario",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  // 2. Beat Question
  Widget _buildQuestionView() {
    final beat = _beats[_currentBeatIndex];
    return GestureDetector(
      onTap: () => setState(() => _currentState = SimulationState.input),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_lastFeedback != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _accentBronze.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: _accentBronze),
                    const SizedBox(width: 8),
                    Text(
                      "${_lastFeedback!['risk'] ?? 'Low'} Risk • ${_lastFeedback!['tone'] ?? 'Neutral'}",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: _accentBronze,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.5),
              const SizedBox(height: 24),
            ],
            Text(
              "BEAT ${beat.beatNumber}",
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: _textDark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              beat.title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _accentBronze,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              beat.question, // This is now dynamically generated from previous step
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _textDark,
                height: 1.2,
              ),
            ).animate(key: ValueKey(beat.beatNumber)).fadeIn().scale(delay: 100.ms),
            const SizedBox(height: 48),
            Text(
              "Tap to answer",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: _textDark.withValues(alpha: 0.5),
              ),
            ).animate().fadeIn(delay: 500.ms).shimmer(),
          ],
        ),
      ),
    );
  }

  // 3. Response Input
  Widget _buildInputView() {
    final beat = _beats[_currentBeatIndex];
    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Beat ${beat.beatNumber}",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: _textDark.withValues(alpha: 0.5),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: _textDark.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),

        // Input Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  beat.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    color: _textDark.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Styled Input Container with Avatar inside
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF9B89A).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Smaller Avatar beside the input
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12.0,
                        ), // Align with first line of text
                        child: ParotMascot(
                          state: _isInputEmpty
                              ? ParotState.idle
                              : ParotState.thinking,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          autofocus: true,
                          maxLines: null,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            color: _textDark,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: beat.placeholder ?? "Type your action...",
                            hintStyle: GoogleFonts.outfit(
                              color: _textDark.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            isDense: true,
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

        // AI Assist & Bottom Actions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showAiAssist) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleGetSuggestions,
                        icon: const Icon(Icons.lightbulb_outline, size: 16),
                        label: const Text("Get suggestions"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textDark,
                          side: BorderSide(
                            color: _textDark.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleEnhanceReply,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Enhance reply"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textDark,
                          side: BorderSide(
                            color: _textDark.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isInputEmpty ? null : _lockInResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.energyAccent, // Indigo
                    disabledBackgroundColor: _textDark.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Lock in response",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!_isInputEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "You won't be able to edit this.",
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: _textDark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Final Summary
  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Simulation Complete",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: _textDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Here's how you did.",
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Strengths",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "You showed great persistence. This is key in real-world scenarios.", // Could be dynamic
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: _textDark.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.trending_up, color: _accentBronze, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Improvement Area",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Watch your risk levels in early beats. Start safer to build rapport.", // Could be dynamic
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: _textDark.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.energyAccent, // Indigo
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Finish",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
