import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/rizz_engine_models.dart';
import '../services/rizz_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/noise_background.dart';

class GuidedSimulationScreen extends StatefulWidget {
  final RizzScenarioConfig config;

  const GuidedSimulationScreen({super.key, required this.config});

  @override
  State<GuidedSimulationScreen> createState() => _GuidedSimulationScreenState();
}

class _GuidedSimulationScreenState extends State<GuidedSimulationScreen> {
  final RizzEngineService _engine = RizzEngineService();
  final TextEditingController _inputController = TextEditingController();

  RizzScenario? _scenario;
  bool _isLoading = true;
  bool _isEnhancing = false;
  String _loadingMessage = "Generating realistic scenario...";

  // Colors
  final Color _primaryDark = AppColors.textPrimary;
  final Color _bgPeach = AppColors.primaryBackground;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Setting the scene...";
    });

    final scenario = await _engine.startScenario(config: widget.config);

    if (mounted) {
      setState(() {
        _scenario = scenario;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitResponse() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Analyzing your move...";
    });

    // Assume user confirmed action
    final updatedScenario = await _engine.submitUserResponse(text);

    if (mounted) {
      setState(() {
        _scenario = updatedScenario;
        _inputController.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _enhanceDraft() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isEnhancing = true);

    final enhanced = await _engine.enhanceResponse(text);

    if (mounted) {
      setState(() {
        _inputController.text = enhanced;
        _isEnhancing = false;
      });
    }
  }

  // UI Components
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _scenario == null) {
      return Scaffold(
        backgroundColor: _bgPeach,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryDark),
              const SizedBox(height: 16),
              Text(
                _loadingMessage,
                style: GoogleFonts.spaceGrotesk(
                  color: _primaryDark,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_scenario == null) {
      return Scaffold(
        backgroundColor: _bgPeach,
        appBar: AppBar(
          backgroundColor: _bgPeach,
          elevation: 0,
          iconTheme: IconThemeData(color: _primaryDark),
        ),
        body: Center(
          child: Text(
            "Failed to load scenario.",
            style: TextStyle(color: _primaryDark),
          ),
        ),
      );
    }

    // Check if completed
    if (_scenario!.isCompleted && !_isLoading) {
      return _buildCompletionScreen();
    }

    // Show current beat
    // beats list has historical beats. The last one is the current one.
    final currentBeat = _scenario!.beats.last;
    final beatIndex = _scenario!.beats.length;

    return Scaffold(
      backgroundColor: _bgPeach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "BEAT $beatIndex",
          style: GoogleFonts.spaceGrotesk(
            color: _primaryDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
      ),
      body: NoiseBackground(
        child: SafeArea(
          child: Column(
            children: [
              // SCENARIO CARD
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Previous Feedback (if any)
                          if (currentBeat.feedbackAnalysis != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryNavy.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "ANALYSIS",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentBeat.feedbackAnalysis!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTag(
                                        "Risk: ${currentBeat.feedbackRisk ?? '?'}",
                                        AppColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildTag(
                                        "Tone: ${currentBeat.feedbackTone ?? '?'}",
                                        AppColors.confidenceIconBg,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: -0.2),
                            const SizedBox(height: 32),
                          ],

                          // Current Question
                          Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: AppColors.primaryBrand.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBrand.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      size: 32,
                                      color: AppColors.secondaryAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      currentBeat.question,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 22, // Slightly adjusted
                                        fontWeight: FontWeight.w600,
                                        color: _primaryDark,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(key: ValueKey(beatIndex))
                              .fadeIn(duration: 500.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                curve: Curves.easeOut,
                              ),

                          const SizedBox(height: 40),

                          // Context Tags (Environment etc) - Subtle
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildTag(
                                _scenario!.config.environment,
                                AppColors.textMuted,
                              ),
                              _buildTag(
                                _scenario!.config.constraint,
                                AppColors.textMuted,
                              ),
                              if (widget.config.stakesLevel == 'Hard')
                                _buildTag("High Stakes", AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // INPUT AREA
              Container(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  12,
                ), // Adjusted padding
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCTA.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Suggestions Row
                    if (!_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _enhanceDraft,
                              icon: _isEnhancing
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primaryDark,
                                      ),
                                    )
                                  : Icon(
                                      Icons.auto_fix_high,
                                      size: 16,
                                      color: AppColors.secondaryAccent,
                                    ),
                              label: Text(
                                "Enhance",
                                style: TextStyle(
                                  color: AppColors.secondaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _inputController,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: currentBeat.placeholder ?? "What do you do?",
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textDisabled,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.focusHighlight,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.secondarySurface,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitResponse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Make Move",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12), // Extra padding for bottom
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    // Simple completion for now
    return Scaffold(
      backgroundColor: _bgPeach,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Scenario Completed",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You navigated the social maze like a pro.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Finish Session",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
