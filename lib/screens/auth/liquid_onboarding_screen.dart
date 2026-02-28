import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import '../../theme/app_theme.dart';

class LiquidOnboardingScreen extends StatefulWidget {
  const LiquidOnboardingScreen({super.key});

  @override
  State<LiquidOnboardingScreen> createState() => _LiquidOnboardingScreenState();
}

class _LiquidOnboardingScreenState extends State<LiquidOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Personal\nguidance.\nAlways ',
      highlightedWord: 'private.',
      description:
          'Infinitely patient, knowledgeable and always available. As you interact with Parot, it actively builds up private memories about you.',
      icon: '🔒',
      showEmoji: true,
    ),
    OnboardingPageData(
      title: 'Practice\nreal-world\n',
      highlightedWord: 'scenarios.',
      description:
          'Train your social skills in a safe, judgment-free environment. Build confidence through realistic AI-powered conversations.',
      icon: '💬',
      showEmoji: true,
    ),
    OnboardingPageData(
      title: 'Track your\nprogress.\nGrow ',
      highlightedWord: 'daily.',
      description:
          'Watch your social confidence improve with detailed analytics and personalized insights. Celebrate every milestone.',
      icon: '📊',
      showEmoji: true,
    ),
  ];

  Future<void> _navigateToAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          // Main Content Area
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildElegantPage(_pages[index], index);
              },
            ),
          ),

          // Bottom Black Section with Button
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFD4A574)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Get Started Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child:
                          ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A574),
                                  foregroundColor: const Color(0xFF1A1A1A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage == _pages.length - 1
                                          ? 'Get started'
                                          : 'Next',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scaleXY(
                                begin: 1.0,
                                end: 1.02,
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantPage(OnboardingPageData data, int index) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Logo Icon with Animation
            if (data.showEmoji)
              Center(
                child:
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              data.icon,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          delay: 100.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then()
                        .shimmer(
                          delay: 800.ms,
                          duration: 1.5.seconds,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
              ),

            const SizedBox(height: 60),

            // Title with Highlighted Word - Using Playfair Display (elegant serif)
            RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: data.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 52,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A1A1A),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: data.highlightedWord,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 52,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFD4A574), // Gold accent
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 800.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 300.ms,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 32),

            // Description Text - Using Outfit (clean sans-serif)
            Text(
                  data.description,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 800.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 500.ms,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                ),

            const Spacer(),

            // Floating decorative elements
            if (index == 0) _buildFloatingLockIcon(),
            if (index == 1) _buildFloatingChatBubbles(),
            if (index == 2) _buildFloatingStars(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLockIcon() {
    return Positioned(
      right: 60,
      top: 380,
      child:
          Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFD4A574),
                  size: 28,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -15,
                duration: 2.5.seconds,
                curve: Curves.easeInOut,
              )
              .fadeIn(delay: 700.ms),
    );
  }

  Widget _buildFloatingChatBubbles() {
    return Stack(
      children: [
        Positioned(
          right: 40,
          top: 360,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Hello! 👋',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .moveY(
                    begin: 0,
                    end: -12,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(delay: 600.ms),
        ),
        Positioned(
          left: 50,
          top: 420,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'Let\'s practice!',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .moveY(
                    begin: 0,
                    end: -10,
                    duration: 2.3.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(delay: 800.ms),
        ),
      ],
    );
  }

  Widget _buildFloatingStars() {
    return Stack(
      children: [
        Positioned(
          right: 60,
          top: 350,
          child:
              const Icon(Icons.star_rounded, color: Color(0xFFD4A574), size: 32)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .rotate(
                    begin: 0,
                    end: 0.1,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(delay: 700.ms),
        ),
        Positioned(
          left: 70,
          top: 400,
          child:
              const Icon(Icons.star_rounded, color: Color(0xFFD4A574), size: 24)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .rotate(
                    begin: 0,
                    end: -0.1,
                    duration: 2.5.seconds,
                    curve: Curves.easeInOut,
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: 2.5.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(delay: 900.ms),
        ),
        Positioned(
          right: 100,
          top: 440,
          child:
              const Icon(Icons.star_rounded, color: Color(0xFFD4A574), size: 20)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .rotate(
                    begin: 0,
                    end: 0.15,
                    duration: 2.2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.25, 1.25),
                    duration: 2.2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(delay: 1100.ms),
        ),
      ],
    );
  }
}

class OnboardingPageData {
  final String title;
  final String highlightedWord;
  final String description;
  final String icon;
  final bool showEmoji;

  OnboardingPageData({
    required this.title,
    required this.highlightedWord,
    required this.description,
    required this.icon,
    this.showEmoji = false,
  });
}
