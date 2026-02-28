import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parot_ai/theme/app_theme.dart';
import 'package:parot_ai/widgets/parot_mascot.dart';
import '../auth/sign_up_screen.dart';
import '../auth/sign_in_screen.dart';

class ParotOnboardingScreen extends StatefulWidget {
  const ParotOnboardingScreen({super.key});

  @override
  State<ParotOnboardingScreen> createState() => _ParotOnboardingScreenState();
}

class _ParotOnboardingScreenState extends State<ParotOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': "Your personal\nspeech coach.",
      'highlight': "speech coach.",
      'subtitle':
          "Master pronunciation with real-time feedback and a friendly guide.",
      'state': ParotState.idle,
    },
    {
      'title': "Perfect your\nClarity.",
      'highlight': "Clarity.",
      'subtitle':
          "Identify areas for improvement and practice until you're perfect.",
      'state': ParotState.listening,
    },
    {
      'title': "Analyze your\nPatterns.",
      'highlight': "Patterns.",
      'subtitle':
          "Parot analyzes your tone and pace to help you sound more natural.",
      'state': ParotState.thinking,
    },
    {
      'title': "Track your\nGrowth.",
      'highlight': "Growth.",
      'subtitle':
          "Watch your confidence score rise after every practice session.",
      'state': ParotState.focused,
    },
    {
      'title': "Speak with\nConfidence.",
      'highlight': "Confidence.",
      'subtitle': "Master any conversation with Parot as your expert guide.",
      'state': ParotState.cool,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeOnboarding', true);

    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // 1. Grid Pattern Background
          Positioned.fill(child: CustomPaint(painter: GridPatternPainter())),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Top Logo
                Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo.png', height: 28),
                            const SizedBox(width: 8),
                            Text(
                              "PAROT",
                              style: AppTextStyles.h3.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "AI-powered social training",
                          style: AppTextStyles.caption.copyWith(
                            letterSpacing: 1,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = _onboardingData[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main Mascot Focus
                          Container(
                                width: 320,
                                height: 320,
                                margin: const EdgeInsets.only(bottom: 40),
                                child: Center(
                                  child: ParotMascot(
                                    state: data['state'] as ParotState,
                                    size: 300,
                                    bounce: true,
                                  ),
                                ),
                              )
                              .animate(key: ValueKey(index))
                              .scale(
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              )
                              .shimmer(duration: 2.seconds, delay: 1.seconds),

                          // Text Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        children: _getFormattedTitle(
                                          data['title'],
                                          data['highlight'],
                                        ),
                                      ),
                                    )
                                    .animate(key: ValueKey('t$index'))
                                    .fadeIn(delay: 200.ms)
                                    .slideY(begin: 0.2, end: 0),

                                const SizedBox(height: 16),

                                Text(
                                      data['subtitle'],
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                    )
                                    .animate(key: ValueKey('s$index'))
                                    .fadeIn(delay: 400.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 3. Footer Section (White Card)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(color: AppColors.primaryNavy, width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_onboardingData.length, (
                          index,
                        ) {
                          return AnimatedContainer(
                            duration: 300.ms,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.primaryBrand
                                  : AppColors.primaryNavy.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      _BlockButton(
                        text: "Get Started",
                        onPressed: _onGetStarted,
                        isPrimary: true,
                        icon: Icons.arrow_forward,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                          GestureDetector(
                            onTap: _onLogin,
                            child: Text(
                              "Sign in",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primaryBrand,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "By continuing, you agree to our Terms & Privacy Policy.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            letterSpacing: 0.2,
                          ),
                        ),
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

  List<TextSpan> _getFormattedTitle(String title, String highlight) {
    List<TextSpan> spans = [];
    List<String> parts = title.split(highlight);

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryNavy,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: highlight,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryBrand,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }
    }
    return spans;
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryNavy.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const double spacing = 24.0;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlockButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  const _BlockButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {}, // For feedback
      onTap: onPressed,
      child: Stack(
        children: [
          // Shadow
          Transform.translate(
            offset: const Offset(4, 4),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.primaryNavy.withValues(alpha: 0.1)
                    : AppColors.primaryBrand,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Main Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primaryNavy : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.buttonText.copyWith(
                      color: isPrimary ? Colors.white : AppColors.primaryNavy,
                      fontSize: 18,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
