import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up_screen.dart';
import 'sign_in_screen.dart';
import '../../theme/app_theme.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Premium Theme Colors
  final Color kBgColor = const Color(0xFFFAE4D7); // Warm Peach
  final Color kPrimaryColor = const Color(0xFF3E2C24); // Dark Warm Brown

  // User selections
  final List<String> _selectedCategories = [];
  bool _cameraEnabled = true;
  bool _microphoneEnabled = true;
  bool _screenOverlayEnabled = false;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Strangers', 'icon': Icons.people_outline_rounded},
    {'title': 'Dating', 'icon': Icons.favorite_border_rounded},
    {'title': 'Social', 'icon': Icons.emoji_events_outlined},
    {'title': 'Small Talk', 'icon': Icons.chat_bubble_outline_rounded},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  // Pages 0 and 1 are Light (Peach bg), Pages 2 and 3 are Dark (Brown bg)
  bool get _isDarkPage => _currentPage > 1;

  @override
  Widget build(BuildContext context) {
    // Dynamic styles based on page theme
    final bgColor = _isDarkPage ? kPrimaryColor : kBgColor;
    final indicatorActiveColor = _isDarkPage ? kBgColor : kPrimaryColor;
    final indicatorInactiveColor = indicatorActiveColor.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Handdraws (Micro Details)
          Positioned(
            top: 80,
            left: -30,
            child: Transform.rotate(
              angle: -0.2,
              child: Opacity(
                opacity: 0.05,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_flower.svg',
                  width: 140,
                  colorFilter: ColorFilter.mode(
                    _isDarkPage ? Colors.white : kPrimaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: Transform.rotate(
              angle: 0.15,
              child: Opacity(
                opacity: 0.05,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_spiral.svg',
                  width: 160,
                  colorFilter: ColorFilter.mode(
                    _isDarkPage ? Colors.white : kPrimaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 20,
            child: Transform.rotate(
              angle: 0.5,
              child: Opacity(
                opacity: 0.03,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_heart.svg',
                  width: 50,
                  colorFilter: ColorFilter.mode(
                    _isDarkPage ? Colors.white : kPrimaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            child: Opacity(
              opacity: 0.04,
              child: SvgPicture.asset(
                'assets/handdraws/undraw_fun-arrow.svg',
                width: 60,
                colorFilter: ColorFilter.mode(
                  _isDarkPage ? Colors.white : kPrimaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildWelcomePage(),
                    _buildCategoryPage(),
                    _buildFeaturesPage(),
                    _buildPermissionsPage(),
                  ],
                ),
              ),

              // Bottom Navigation Area (Hidden on First Page as it has its own button)
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress Indicator
                      Row(
                        children: List.generate(
                          _totalPages,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: index == _currentPage ? 28 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? indicatorActiveColor
                                  : indicatorInactiveColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Next Button
                      GestureDetector(
                        onTap: _canProceed() ? _nextPage : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _canProceed()
                                ? indicatorActiveColor
                                : indicatorActiveColor.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == _totalPages - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: _isDarkPage ? kPrimaryColor : kBgColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Top Right Skip Button (Visible on pages > 0)
          if (_currentPage > 0)
            Positioned(
              top: 50,
              right: 24,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isDarkPage
                        ? Colors.white.withValues(alpha: 0.7)
                        : kPrimaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentPage == 1) {
      return _selectedCategories.isNotEmpty;
    }
    return true;
  }

  // SCREEN 1: Welcome - Large Illustration, No Top Branding
  Widget _buildWelcomePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),

            // Hero Illustration (Maximized Size, No Animation)
            Expanded(
              flex: 4,
              child:
                  SvgPicture.asset(
                        'assets/undraw_social-ideas_3znc.svg',
                        fit: BoxFit.contain,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
            ),

            const Spacer(),

            // Headline & Subtitle
            Text(
              "Master your\npresence.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                height: 1.1,
                letterSpacing: -1.0,
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 16),

            Text(
              "Your personal AI coach for confidence,\ntone, and charisma in every conversation.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: kPrimaryColor.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const Spacer(),

            // CTA Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.energyAccent, // Indigo
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      "Start Training",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I already have an account",
                        style: GoogleFonts.manrope(
                          color: AppColors.energyAccent, // Indigo link
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.energyAccent,
                      ),
                    ],
                  ),
                ).animate(delay: 600.ms).fadeIn(),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // SCREEN 2: Category Selection
  Widget _buildCategoryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            'Where do you\nneed confidence?',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: kPrimaryColor,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Text(
            'Select areas to improve',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: kPrimaryColor.withValues(alpha: 0.7),
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(
                  category['title'],
                );
                return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(category['title']);
                          } else {
                            _selectedCategories.add(category['title']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? kPrimaryColor
                                : kPrimaryColor.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : kBgColor.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category['icon'],
                                size: 28,
                                color: isSelected
                                    ? Colors.white
                                    : kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              category['title'],
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : kPrimaryColor,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ).animate().scale(),
                            ],
                          ],
                        ),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 3: How it works
  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            'How it works',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Text(
            'Your path to better conversations.',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 40),
          Column(
            children: [
              _buildFeatureRow(
                icon: Icons.psychology_rounded,
                title: 'Your AI Coach',
                description: 'Personalized guidance based on your goals.',
                delay: 0,
              ),
              _buildDivider(),
              _buildFeatureRow(
                icon: Icons.mic_rounded,
                title: 'Practice Mode',
                description: 'Realistic voice conversations without pressure.',
                delay: 100,
              ),
              _buildDivider(),
              _buildFeatureRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Real-time Aura',
                description: 'Live feedback during your practice sessions.',
                delay: 200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.1);
  }

  // SCREEN 4: Permissions
  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            'Enable coaching',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Text(
            'Permissions allow the AI to\nanalyze and guide you.',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 48),
          _buildPremiumPermissionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Camera Access',
            description: 'For posture & eye contact.',
            value: _cameraEnabled,
            onChanged: (val) => setState(() => _cameraEnabled = val),
            delay: 0,
          ),
          const SizedBox(height: 16),
          _buildPremiumPermissionCard(
            icon: Icons.mic_none_outlined,
            title: 'Microphone',
            description: 'For voice tone & clarity.',
            value: _microphoneEnabled,
            onChanged: (val) => setState(() => _microphoneEnabled = val),
            delay: 100,
          ),
          const SizedBox(height: 16),
          _buildPremiumPermissionCard(
            icon: Icons.phone_android_outlined,
            title: 'Screen Overlay',
            description: 'Display live tips.',
            value: _screenOverlayEnabled,
            onChanged: (val) => setState(() => _screenOverlayEnabled = val),
            delay: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value ? Colors.white : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? kPrimaryColor : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: kPrimaryColor.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.1);
  }
}
