import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/parot_mascot.dart';

class TourStep {
  final String title;
  final String description;
  final ParotState mascotState;
  final Alignment mascotAlignment;
  final Alignment boxAlignment;

  TourStep({
    required this.title,
    required this.description,
    required this.mascotState,
    this.mascotAlignment = Alignment.center,
    this.boxAlignment = Alignment.center,
  });
}

class DashboardTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const DashboardTourOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<DashboardTourOverlay> createState() => _DashboardTourOverlayState();
}

class _DashboardTourOverlayState extends State<DashboardTourOverlay> {
  int _currentStep = 0;

  final List<TourStep> _steps = [
    TourStep(
      title: "Welcome aboard! 🦜",
      description:
          "I'm Parot, your personal social coach. Let me show you how to get the most out of your training.",
      mascotState: ParotState.waving,
      mascotAlignment: const Alignment(0, -0.3),
      boxAlignment: const Alignment(0, 0.2),
    ),
    TourStep(
      title: "Daily Insights",
      description:
          "This is your Home. I'll provide daily focus areas and track your consistency right here.",
      mascotState: ParotState.pointingLeft,
      mascotAlignment: const Alignment(0.6, 0.8),
      boxAlignment: const Alignment(0, 0.5),
    ),
    TourStep(
      title: "Practice Arenas",
      description:
          "Explore diverse Scenarios to practice everything from networking to conflict resolution.",
      mascotState: ParotState.pointingLeft,
      mascotAlignment: const Alignment(0.2, 0.8),
      boxAlignment: const Alignment(0, 0.5),
    ),
    TourStep(
      title: "Your AI Coach",
      description:
          "Tap me here to start an immersive, real-time coaching session tailored just for you.",
      mascotState: ParotState.pointingDown,
      mascotAlignment: const Alignment(0, 0.75),
      boxAlignment: const Alignment(0, 0.3),
    ),
    TourStep(
      title: "Quick Chat",
      description:
          "Have a specific question? The AI Assistant is ready to help you prepare for any situation.",
      mascotState: ParotState.pointingRight,
      mascotAlignment: const Alignment(-0.2, 0.8),
      boxAlignment: const Alignment(0, 0.5),
    ),
    TourStep(
      title: "Track Growth",
      description:
          "Watch your Social Power grow! Keep an eye on your progress and aim for the next level.",
      mascotState: ParotState.pointingRight,
      mascotAlignment: const Alignment(-0.6, 0.8),
      boxAlignment: const Alignment(0, 0.5),
    ),
    TourStep(
      title: "Ready to fly?",
      description:
          "That's it for the guided tour. I can't wait to see you excel. Let's start training!",
      mascotState: ParotState.excited,
      mascotAlignment: const Alignment(0, -0.2),
      boxAlignment: const Alignment(0, 0.3),
    ),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Background Dim
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Skip Button
          Positioned(
            top: 60,
            right: 24,
            child: GestureDetector(
              onTap: widget.onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Skip Tour",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1.seconds),

          // Mascot
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutBack,
            alignment: step.mascotAlignment,
            child: ParotMascot(state: step.mascotState, size: 160)
                .animate(key: ValueKey(_currentStep))
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),

          // Info Box
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: step.boxAlignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child:
                  Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryNavy,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBrand.withValues(
                                alpha: 0.3,
                              ),
                              offset: const Offset(6, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step.title,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.primaryNavy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.description,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _next,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _currentStep == _steps.length - 1
                                      ? "Let's Go!"
                                      : "Next Step",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(key: ValueKey(_currentStep))
                      .fadeIn()
                      .slideY(begin: 0.2),
            ),
          ),

          // Progress Indicator
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  width: 30,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? AppColors.primaryBrand
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
