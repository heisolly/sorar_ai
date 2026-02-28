import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../dashboard_screen.dart';
import '../auth/daily_reminder_onboarding.dart';
import '../../widgets/parot_mascot.dart';
import '../../config/navigation_key.dart';

class PersonalizationFlow extends StatefulWidget {
  const PersonalizationFlow({super.key});

  @override
  State<PersonalizationFlow> createState() => _PersonalizationFlowState();
}

class _PersonalizationFlowState extends State<PersonalizationFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 10;

  // User Data
  String _userName = '';
  String _gender = '';
  int _age = 25;
  final List<String> _mainGoals = [];
  final List<String> _challenges = [];
  String _anxietyFrequency = '';
  String _confidenceLevel = '';
  String _triedCoachingBefore = '';
  String _communicationStyle = '';
  double _preparingProgress = 0;
  bool _isBlowingComplete = false;
  bool _showFlowers = false;

  // Options Data
  final List<Map<String, dynamic>> _goalOptions = [
    {'title': 'Better Dating Skills', 'icon': Icons.favorite_outline},
    {'title': 'Professional Networking', 'icon': Icons.handshake_outlined},
    {'title': 'Public Speaking', 'icon': Icons.campaign_outlined},
    {'title': 'Everyday Conversations', 'icon': Icons.chat_bubble_outline},
    {'title': 'Conflict Resolution', 'icon': Icons.psychology_outlined},
    {'title': 'Building Confidence', 'icon': Icons.emoji_events_outlined},
  ];

  final List<Map<String, dynamic>> _challengeOptions = [
    {'title': 'Starting conversations', 'icon': Icons.waving_hand_outlined},
    {'title': 'Keeping conversations going', 'icon': Icons.repeat_rounded},
    {'title': 'Making eye contact', 'icon': Icons.remove_red_eye_outlined},
    {'title': 'Speaking in groups', 'icon': Icons.groups_outlined},
    {
      'title': 'Handling rejection',
      'icon': Icons.sentiment_dissatisfied_outlined,
    },
    {'title': 'Being assertive', 'icon': Icons.record_voice_over_outlined},
  ];

  final List<String> _frequencyOptions = [
    'Almost always',
    'Often',
    'Sometimes',
    'Rarely',
    'Almost never',
  ];

  final List<String> _confidenceOptions = [
    'Very low',
    'Low',
    'Moderate',
    'High',
    'Very high',
  ];

  final List<String> _coachingOptions = [
    "Yes, I have",
    "No, this is my first time",
    "I've tried self-help resources",
  ];

  final List<String> _styleOptions = [
    'Direct and to the point',
    'Friendly and warm',
    'Analytical and detailed',
    'Enthusiastic and expressive',
  ];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _userName.trim().isNotEmpty;
      case 1:
        return _gender.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _mainGoals.isNotEmpty;
      case 4:
        return _challenges.isNotEmpty;
      case 5:
        return _anxietyFrequency.isNotEmpty;
      case 6:
        return _confidenceLevel.isNotEmpty;
      case 7:
        return _triedCoachingBefore.isNotEmpty;
      case 8:
        return _communicationStyle.isNotEmpty;
      default:
        return true;
    }
  }

  void _startPreparing() async {
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() => _preparingProgress = i / 100);
      }
    }

    try {
      final profileService = UserProfileService();
      await profileService.saveUserProfile(
        userName: _userName,
        gender: _gender,
        age: _age,
        mainGoals: _mainGoals,
        challenges: _challenges,
        anxietyFrequency: _anxietyFrequency,
        confidenceLevel: _confidenceLevel,
        triedCoachingBefore: _triedCoachingBefore,
        communicationStyle: _communicationStyle,
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }

    if (mounted) {
      setState(() {
        _preparingProgress = 1.0;
        _showFlowers = true;
      });
    }

    // Wait for the blowing animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() => _isBlowingComplete = true);
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DailyReminderOnboarding(
            onComplete: () {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  Color _getStepBackgroundColor() {
    if (_currentStep == 5) {
      switch (_anxietyFrequency) {
        case 'Almost always':
          return const Color(0xFFFFCCCC); // Subtle Red
        case 'Often':
          return const Color(0xFFFFF0F0); // Very Light Red
        case 'Sometimes':
          return const Color(0xFFFFF7F0); // Warm Peach
        case 'Rarely':
          return const Color(0xFFFAEDE6); // Default-ish
        default:
          return AppColors.primaryBackground;
      }
    }
    return AppColors.primaryBackground;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        color: _getStepBackgroundColor(),
        child: Stack(
          children: [
            // 1. Grid Pattern Background
            Positioned.fill(child: CustomPaint(painter: GridPatternPainter())),

            // 2. Anxious Drops Overlay (only for high anxiety)
            if (_currentStep == 5 && _anxietyFrequency == 'Almost always')
              const Positioned.fill(child: _FloatingDropsOverlay()),

            SafeArea(
              child: Column(
                children: [
                  // Top Logo
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', height: 24),
                        const SizedBox(width: 8),
                        Text(
                          "PAROT",
                          style: AppTextStyles.h3.copyWith(
                            letterSpacing: 4,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Header
                  _buildProgressHeader(),

                  // Page Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                        if (index == _totalSteps - 1) {
                          _startPreparing();
                        }
                      },
                      children: [
                        _buildStepWrapper(
                          _buildNameStep(),
                          ParotState.listening,
                        ),
                        _buildStepWrapper(
                          _buildGenderStep(),
                          _gender == 'Male'
                              ? ParotState.male
                              : (_gender == 'Female'
                                    ? ParotState.female
                                    : ParotState.idle),
                        ),
                        _buildStepWrapper(
                          _buildAgeStep(),
                          _age < 20
                              ? ParotState.ageTeens
                              : (_age < 35
                                    ? ParotState.age20s
                                    : (_age < 50
                                          ? ParotState.age40s
                                          : (_age < 70
                                                ? ParotState.age60s
                                                : ParotState.ageSenior))),
                        ),
                        _buildStepWrapper(
                          _buildGoalsStep(),
                          _mainGoals.isEmpty
                              ? ParotState.idle
                              : (_mainGoals.length < 3
                                    ? ParotState.happy
                                    : ParotState.excited),
                        ),
                        _buildStepWrapper(
                          _buildChallengesStep(),
                          _challenges.isEmpty
                              ? ParotState.sympathy
                              : ParotState.happy,
                        ),
                        _buildStepWrapper(
                          _buildAnxietyStep(),
                          _anxietyFrequency == 'Almost always'
                              ? ParotState.anxious
                              : (_anxietyFrequency == 'Often'
                                    ? ParotState.oops
                                    : (_anxietyFrequency == 'Sometimes'
                                          ? ParotState.confused
                                          : (_anxietyFrequency == 'Rarely'
                                                ? ParotState.idle
                                                : ParotState.happy))),
                        ),
                        _buildStepWrapper(
                          _buildConfidenceStep(),
                          _confidenceLevel == 'Very high'
                              ? ParotState.excited
                              : (_confidenceLevel == 'High'
                                    ? ParotState.proud
                                    : (_confidenceLevel == 'Moderate'
                                          ? ParotState.happy
                                          : (_confidenceLevel == 'Low'
                                                ? ParotState.idle
                                                : (_confidenceLevel ==
                                                          'Very low'
                                                      ? ParotState.sad
                                                      : ParotState.idle)))),
                        ),
                        _buildStepWrapper(
                          _buildCoachingStep(),
                          ParotState.study,
                        ),
                        _buildStepWrapper(
                          _buildStyleStep(),
                          _communicationStyle == 'Direct and to the point'
                              ? ParotState.proud
                              : (_communicationStyle == 'Friendly and warm'
                                    ? ParotState.happy
                                    : (_communicationStyle ==
                                              'Analytical and detailed'
                                          ? ParotState.thinking
                                          : (_communicationStyle ==
                                                    'Enthusiastic and expressive'
                                                ? ParotState.excited
                                                : ParotState.happy))),
                        ),
                        _buildPreparingStep(),
                      ],
                    ),
                  ),

                  // Continue Button (not on last step)
                  if (_currentStep < _totalSteps - 1) _buildContinueButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWrapper(Widget child, ParotState mascotState) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Transform.rotate(
              angle: -0.05,
              child: ParotMascot(state: mascotState, size: 100),
            )
            .animate(key: ValueKey(_currentStep))
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryNavy,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              const Spacer(),
              if (_currentStep < _totalSteps - 1)
                Text(
                  'Step ${_currentStep + 1} of ${_totalSteps - 1}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
              const Spacer(),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 16),
          // Neobrutalist Progress bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBrand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canProceed = _canProceed();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _NeobrutalistButton(
        text: 'Continue',
        onPressed: _nextStep,
        enabled: canProceed,
      ),
    );
  }

  // ========== STEPS ==========

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading('What should we call you?'),
          _buildSubheading("We'll use this to personalize your experience"),
          const SizedBox(height: 32),
          _buildNeobrutalistTextField(
            onChanged: (val) => setState(() => _userName = val),
            hint: 'Enter your name',
          ),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading('What is your gender?'),
          _buildSubheading('This helps us tailor scenarios for you'),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildGenderOption('Male', Icons.male_rounded)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption('Female', Icons.female_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGenderOption('Other', Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, IconData icon) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: _NeobrutalistSelectionCard(
        isSelected: isSelected,
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading('How old are you?'),
          _buildSubheading('Age-appropriate scenarios for better learning'),
          const SizedBox(height: 32),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => _age = 16 + index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 65,
                builder: (context, index) {
                  final age = 16 + index;
                  final isSelected = age == _age;
                  return Center(
                    child: Text(
                      '$age',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primaryBrand
                            : AppColors.primaryNavy.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return _buildMultiSelectGrid(
      'What are your main goals?',
      'Select all that apply',
      _goalOptions,
      _mainGoals,
    );
  }

  Widget _buildChallengesStep() {
    return _buildMultiSelectGrid(
      'What challenges you most?',
      'Select all that apply',
      _challengeOptions,
      _challenges,
    );
  }

  Widget _buildMultiSelectGrid(
    String title,
    String subtitle,
    List<Map<String, dynamic>> options,
    List<String> selectedList,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(title),
          _buildSubheading(subtitle),
          const SizedBox(height: 24),
          ...options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMultiSelectOption(
                opt['title'],
                opt['icon'],
                selectedList,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectOption(
    String title,
    IconData icon,
    List<String> selectedList,
  ) {
    final isSelected = selectedList.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedList.remove(title);
          } else {
            selectedList.add(title);
          }
        });
      },
      child: _NeobrutalistSelectionCard(
        isSelected: isSelected,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.primaryNavy,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildAnxietyStep() {
    return _buildSingleSelectGrid(
      'How often do you feel anxious?',
      _frequencyOptions,
      _anxietyFrequency,
      (val) => setState(() => _anxietyFrequency = val),
    );
  }

  Widget _buildConfidenceStep() {
    return _buildSingleSelectGrid(
      'Rate your current confidence',
      _confidenceOptions,
      _confidenceLevel,
      (val) => setState(() => _confidenceLevel = val),
    );
  }

  Widget _buildCoachingStep() {
    return _buildSingleSelectGrid(
      'Tried coaching before?',
      _coachingOptions,
      _triedCoachingBefore,
      (val) => setState(() => _triedCoachingBefore = val),
    );
  }

  Widget _buildStyleStep() {
    return _buildSingleSelectGrid(
      'Describe your communication style',
      _styleOptions,
      _communicationStyle,
      (val) => setState(() => _communicationStyle = val),
    );
  }

  Widget _buildSingleSelectGrid(
    String title,
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(title),
          const SizedBox(height: 24),
          ...options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(opt),
                child: _NeobrutalistSelectionCard(
                  isSelected: selected == opt,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected == opt
                                ? Colors.white
                                : AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      if (selected == opt)
                        const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparingStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ParotMascot(
                state: _isBlowingComplete
                    ? ParotState.winner
                    : (_showFlowers ? ParotState.blowing : ParotState.loading),
                size: 200,
              ),
              if (_showFlowers)
                Positioned.fill(
                  child: _FlowerBlowOverlay(isComplete: _isBlowingComplete),
                ),
              if (!_showFlowers)
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: _preparingProgress,
                    strokeWidth: 12,
                    backgroundColor: AppColors.primaryNavy.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBrand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            _isBlowingComplete ? 'All set!' : 'Crafting your plan...',
            style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            _isBlowingComplete
                ? 'Your personalized program is ready to go.'
                : 'Analyzing your style to create the\nperfect training program.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 32),
          if (!_showFlowers)
            Text(
              '${(_preparingProgress * 100).toInt()}%',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primaryBrand,
                fontSize: 48,
              ),
            ),
        ],
      ),
    );
  }

  // ========== STEPS HELPERS ==========

  Widget _buildHeading(String text) {
    return Text(
      text,
      style: AppTextStyles.h1.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryNavy,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSubheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildNeobrutalistTextField({
    required Function(String) onChanged,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryNavy, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.1),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

class _FlowerBlowOverlay extends StatefulWidget {
  final bool isComplete;
  const _FlowerBlowOverlay({required this.isComplete});

  @override
  State<_FlowerBlowOverlay> createState() => _FlowerBlowOverlayState();
}

class _FlowerBlowOverlayState extends State<_FlowerBlowOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FlowerParticle> _particles = List.generate(
    20,
    (index) => _FlowerParticle(),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FlowerPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _FlowerParticle {
  final double initialX = 0.5;
  final double initialY = 0.45;
  late double targetX;
  late double targetY;
  late double size;
  late Color color;
  late double drift;

  _FlowerParticle() {
    final random = math.Random();
    targetX = 0.1 + random.nextDouble() * 0.8;
    targetY = -0.2 - random.nextDouble() * 0.3;
    size = 10 + random.nextDouble() * 15;
    drift = (random.nextDouble() - 0.5) * 0.2;
    color = [
      AppColors.primaryBrand,
      AppColors.parotYellow,
      const Color(0xFF64B5F6),
      const Color(0xFF81C784),
    ][random.nextInt(4)];
  }
}

class _FlowerPainter extends CustomPainter {
  final List<_FlowerParticle> particles;
  final double progress;

  _FlowerPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.05) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final double t = (progress - 0.05) / 0.95;
      if (t < 0) continue;

      // Burst out from center
      final double x =
          size.width *
          (p.initialX +
              (p.targetX - p.initialX) * t +
              math.sin(t * 8) * p.drift);
      final double y =
          size.height * (p.initialY + (p.targetY - p.initialY) * t);

      final double opacity = t > 0.8 ? (1.0 - t) * 5 : 1.0;
      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      // Draw a simple flower/petal shape
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10);

      for (int i = 0; i < 5; i++) {
        canvas.rotate(72 * 0.0174533); // 72 degrees in radians
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(5, 0),
            width: p.size,
            height: p.size / 2,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NeobrutalistSelectionCard extends StatelessWidget {
  final bool isSelected;
  final Widget child;
  final EdgeInsets padding;

  const _NeobrutalistSelectionCard({
    required this.isSelected,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryNavy, width: 2),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryBrand.withValues(alpha: 0.3)
                : AppColors.primaryNavy.withValues(alpha: 0.1),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NeobrutalistButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const _NeobrutalistButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Stack(
        children: [
          // Shadow
          Transform.translate(
            offset: const Offset(4, 4),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primaryBrand
                    : AppColors.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Main Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primaryNavy : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
            ),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.buttonText.copyWith(
                  color: enabled
                      ? Colors.white
                      : AppColors.primaryNavy.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _FloatingDropsOverlay extends StatefulWidget {
  const _FloatingDropsOverlay();

  @override
  State<_FloatingDropsOverlay> createState() => _FloatingDropsOverlayState();
}

class _FloatingDropsOverlayState extends State<_FloatingDropsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _DropsPainter(progress: _controller.value));
      },
    );
  }
}

class _DropsPainter extends CustomPainter {
  final double progress;
  _DropsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw multiple falling drops
    for (int i = 0; i < 6; i++) {
      final double x = (size.width / 5) * i + (10 * i % 30);
      final double yStart = (size.height / 3) * (i % 3);
      final double y =
          yStart + (size.height / 2) * ((progress + i * 0.2) % 1.0);

      canvas.drawPath(_createDropPath(x, y), paint);
    }
  }

  Path _createDropPath(double x, double y) {
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x - 6, y + 10, x, y + 15);
    path.quadraticBezierTo(x + 6, y + 10, x, y);
    return path;
  }

  @override
  bool shouldRepaint(covariant _DropsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
