import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parot_ai/theme/app_theme.dart';
import 'package:parot_ai/widgets/parot_mascot.dart';
import 'package:parot_ai/widgets/speech_waveform.dart';

class SpeechSessionScreen extends StatefulWidget {
  final String scenarioTitle;

  const SpeechSessionScreen({
    super.key,
    this.scenarioTitle = "Casual Conversation",
  });

  @override
  State<SpeechSessionScreen> createState() => _SpeechSessionScreenState();
}

class _SpeechSessionScreenState extends State<SpeechSessionScreen> {
  bool _isListening = false;
  double _voicePower = 0.0;
  ParotState _mascotState = ParotState.idle;
  String _currentText = "Tap the mic when you're ready to speak!";

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _mascotState = ParotState.listening;
        _currentText = "I'm listening...";
        _startSimulatedVoice();
      } else {
        _mascotState = ParotState.talking;
        _currentText = "Processing your brilliance...";
        _voicePower = 0.0;
        _simulateResponse();
      }
    });
  }

  void _startSimulatedVoice() async {
    while (_isListening) {
      if (!mounted) break;
      setState(() {
        _voicePower = (DateTime.now().millisecond % 100) / 100.0;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _simulateResponse() async {
    await Future.delayed(2.seconds);
    if (!mounted) return;
    setState(() {
      _mascotState = ParotState.happy;
      _currentText = "That sounded great! Your clarity is improving.";
    });
    await Future.delayed(3.seconds);
    if (!mounted) return;
    setState(() {
      _mascotState = ParotState.idle;
      _currentText = "Ready for the next one?";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(widget.scenarioTitle, style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            children: [
              // Top: Parot Mascot
              Expanded(
                flex: 4,
                child: Center(
                  child: ParotMascot(state: _mascotState, size: 280),
                ),
              ),

              // Middle: Waveform / Text
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                          _currentText,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate(key: ValueKey(_currentText))
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 48),

                    SpeechWaveform(
                      isListening: _isListening,
                      power: _voicePower,
                    ),
                  ],
                ),
              ),

              // Bottom: Action Button
              Expanded(
                flex: 2,
                child: Center(
                  child: GestureDetector(
                    onVerticalDragUpdate:
                        (details) {}, // Placeholder for swipe gestures
                    onTap: _toggleListening,
                    child:
                        AnimatedContainer(
                              duration: 300.ms,
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? AppColors.primaryBrand
                                    : AppColors.primaryNavy,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_isListening
                                                ? AppColors.primaryBrand
                                                : AppColors.primaryNavy)
                                            .withAlpha(76), // 0.3 * 255 = 76.5
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            )
                            .animate(target: _isListening ? 1 : 0)
                            .shimmer(
                              duration: 2.seconds,
                              color: Colors.white.withAlpha(
                                76,
                              ), // 0.3 * 255 = 76.5
                            ),
                  ),
                ),
              ),

              Text(
                _isListening ? "TAP TO STOP" : "TAP TO SPEAK",
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(delay: 1.seconds),
            ],
          ),
        ),
      ),
    );
  }
}
