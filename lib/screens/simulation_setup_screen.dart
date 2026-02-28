import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import 'coach_screen.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../widgets/parot_mascot.dart';
import '../widgets/motion/smooth_fade_in.dart';
import '../widgets/motion/pressable_scale.dart';

class SimulationSetupScreen extends StatefulWidget {
  const SimulationSetupScreen({super.key});

  @override
  State<SimulationSetupScreen> createState() => _SimulationSetupScreenState();
}

class _SimulationSetupScreenState extends State<SimulationSetupScreen> {
  final _supabase = SupabaseService();
  String _selectedMode = 'practice';
  bool _userStarts = false;
  final TextEditingController _scenarioController = TextEditingController();

  final Map<String, List<String>> _scenarioExamples = {
    'Rizz': [
      "I saw a cute girl at the coffee shop reading a book I love. How do I approach her?",
      "Sliding into the DMs of someone I met briefly at a party.",
      "I want to ask my gym crush out without making it awkward.",
    ],
    'Family': [
      "I need to tell my parents I'm dropping out of college.",
      "Apologizing to my sister for forgetting her birthday.",
      "Convincing my dad to let me borrow the car for a road trip.",
    ],
    'Business': [
      "Asking my boss for a raise during my performance review.",
      "Negotiating a deadline extension with a difficult client.",
      "Giving constructive feedback to an underperforming colleague.",
    ],
    'Conflict': [
      "Confronting a roommate who never washes their dishes.",
      "Breaking up with a partner of 3 years gently.",
      "Addressing a friend who keeps flaking on plans.",
    ],
    'Negotiation': [
      "Buying a used car and trying to lower the price.",
      "Negotiating my salary for a new job offer.",
      "Convincing my landlord not to raise the rent.",
    ],
  };

  // Category metadata: icon, color
  final Map<String, Map<String, dynamic>> _categoryMeta = {
    'Rizz': {'icon': Icons.favorite_rounded, 'color': AppColors.scenarioRizz},
    'Family': {'icon': Icons.people_rounded, 'color': AppColors.scenarioFamily},
    'Business': {
      'icon': Icons.business_center_rounded,
      'color': AppColors.scenarioBusiness,
    },
    'Conflict': {
      'icon': Icons.flash_on_rounded,
      'color': AppColors.scenarioConflict,
    },
    'Negotiation': {
      'icon': Icons.handshake_rounded,
      'color': AppColors.scenarioNegotiation,
    },
  };

  String _selectedCategory = 'Rizz';

  final ValueNotifier<List<Map<String, dynamic>>> _historySessionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingHistoryNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _historySessionsNotifier.dispose();
    _isLoadingHistoryNotifier.dispose();
    _scenarioController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_historySessionsNotifier.value.isEmpty) {
      _isLoadingHistoryNotifier.value = true;
    }
    try {
      final sessions = await _supabase.getChatSessions(limit: 20);
      if (mounted) _historySessionsNotifier.value = sessions;
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) _isLoadingHistoryNotifier.value = false;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      drawer: _buildHistoryDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) _loadHistory();
      },
      body: Stack(
        children: [
          // Handdraw background decoration (top right)
          Positioned(
            top: -10,
            right: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_spiral.svg',
                  width: 160,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryBrand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          // Handdraw bottom left
          Positioned(
            bottom: 100,
            left: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_three-lines.svg',
                  width: 120,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryNavy,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                _buildTopBar(),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Page title + mascot row
                        _buildPageHeader(),

                        const SizedBox(height: 28),

                        // Hero card: Free-form simulator
                        _buildFreePlayCard(),

                        const SizedBox(height: 28),

                        // Practice packs — category chips + examples
                        _buildPracticePacksSection(),

                        const SizedBox(height: 28),

                        // Scenario text input
                        _buildScenarioInput(),

                        const SizedBox(height: 28),

                        // AI Role selector
                        _buildSectionLabel(
                          'AI ROLE',
                          icon: Icons.psychology_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildRoleSelector(),

                        const SizedBox(height: 24),

                        // Who starts toggle
                        _buildWhoStartsToggle(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // ── CTA button ─────────────────────────────────────────────
                _buildStartButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // History button (drawer)
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMenu01,
                color: AppColors.primaryNavy,
                size: 24,
              ),
              tooltip: 'History',
            ),
          ),
          const Spacer(),
          // Notification / info button
          IconButton(
            onPressed: () {},
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: AppColors.primaryNavy,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── Page header ────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guided',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavy,
                    height: 1.0,
                    letterSpacing: -1.2,
                  ),
                ),
                Text(
                  'Simulations',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBrand,
                    height: 1.0,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Master any social situation with Parot\'s AI',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mascot with speech bubble feel
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrand.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: ParotMascot(state: ParotState.encouraging, size: 58),
                ),
              ),
              Positioned(
                top: -8,
                right: -4,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_fun-arrow.svg',
                  width: 28,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryBrand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Free-play hero card ────────────────────────────────────────────────────

  Widget _buildFreePlayCard() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 160),
      child: PressableScale(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CoachScreen(simulationType: 'roleplay'),
          ),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: -40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBrand.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Handdraw sparkle top-right
                Positioned(
                  top: 16,
                  right: 16,
                  child: SvgPicture.asset(
                    'assets/handdraws/undraw_exclamation-point.svg',
                    width: 32,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FREE PLAY badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBrand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'FREE PLAY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Real Life\nSimulator',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Describe any situation and walk\nthrough it with Parot\'s guidance.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Start button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Start Engine',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
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
      ),
    );
  }

  // ── Practice packs section ─────────────────────────────────────────────────

  Widget _buildPracticePacksSection() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Handdraw underline accent
              SvgPicture.asset(
                'assets/handdraws/undraw_two-lines.svg',
                width: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryBrand,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRACTICE PACKS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _scenarioExamples.keys.map((cat) {
                final isSelected = _selectedCategory == cat;
                final meta = _categoryMeta[cat]!;
                final color = meta['color'] as Color;
                final icon = meta['icon'] as IconData;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PressableScale(
                    onPressed: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: AppMotion.kMedium,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Example cards (2-col grid)
          _buildExampleGrid(),
        ],
      ),
    );
  }

  Widget _buildExampleGrid() {
    final examples = _scenarioExamples[_selectedCategory]!;
    final color = _categoryMeta[_selectedCategory]!['color'] as Color;

    return Column(
      children: examples.map((example) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PressableScale(
            onPressed: () => setState(() => _scenarioController.text = example),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryMeta[_selectedCategory]!['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      example,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: color.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Scenario input ─────────────────────────────────────────────────────────

  Widget _buildScenarioInput() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('YOUR SCENARIO', icon: Icons.edit_note_rounded),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _scenarioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe specifically what you want to practice…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textDisabled,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(18),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role selector ──────────────────────────────────────────────────────────

  Widget _buildRoleSelector() {
    return Column(
      children: [
        _buildRoleOption(
          id: 'practice',
          icon: HugeIcons.strokeRoundedUserMultiple,
          color: AppColors.primaryBrand,
          label: 'AI plays THEM',
          desc: 'You are yourself. Parot plays the other person.',
        ),
        const SizedBox(height: 10),
        _buildRoleOption(
          id: 'assistant',
          icon: HugeIcons.strokeRoundedUserCircle,
          color: const Color(0xFF7C3AED),
          label: 'AI plays ME',
          desc: 'Parot plays YOU. You play the other person.',
        ),
        const SizedBox(height: 10),
        _buildRoleOption(
          id: 'hybrid',
          icon: HugeIcons.strokeRoundedMagicWand01,
          color: const Color(0xFF0EA5E9),
          label: 'Hybrid Mode',
          desc: 'Flexible: chat yourself, or let Parot take over.',
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String id,
    required List<List<dynamic>> icon,
    required Color color,
    required String label,
    required String desc,
  }) {
    final isSelected = _selectedMode == id;

    return PressableScale(
      onPressed: () => setState(() => _selectedMode = id),
      child: AnimatedContainer(
        duration: AppMotion.kFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: isSelected ? Colors.white : color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Who starts toggle ──────────────────────────────────────────────────────

  Widget _buildWhoStartsToggle() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 380),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primaryBrand,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _userStarts
                    ? 'You start the conversation'
                    : 'Parot starts first',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            Switch.adaptive(
              value: _userStarts,
              onChanged: (val) => setState(() => _userStarts = val),
              activeThumbColor: AppColors.primaryBrand,
              activeTrackColor: AppColors.primaryBrand.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start button ───────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 420),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: PressableScale(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoachScreen(
                  simulationType: 'roleplay',
                  roleMode: _selectedMode,
                  initialScenario: _scenarioController.text,
                  userStarts: _userStarts,
                ),
              ),
            );
          },
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBrand, Color(0xFFFF8C42)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBrand.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Start Simulation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryBrand),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  // ── History Drawer ─────────────────────────────────────────────────────────

  Widget _buildHistoryDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoadingHistoryNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBrand,
                    ),
                  );
                }
                return ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _historySessionsNotifier,
                  builder: (context, sessions, child) {
                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ParotMascot(
                              state: ParotState.thinking,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent simulations',
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start one to build your history',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _loadHistory,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryBrand,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final date = DateTime.parse(
                          session['created_at'],
                        ).toLocal();
                        final metadata = session['metadata'] ?? {};
                        final title =
                            metadata['scenario_title'] ?? 'Simulation';

                        return Dismissible(
                          key: Key(session['id']),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (dir) =>
                              _showDeleteDialog(session['id']),
                          onDismissed: (_) => _deleteSession(session['id']),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBrand.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: AppColors.primaryBrand,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat('MMM d • h:mm a').format(date),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.textDisabled,
                                ),
                                onPressed: () async {
                                  final confirm = await _showDeleteDialog(
                                    session['id'],
                                  );
                                  if (confirm == true) {
                                    _deleteSession(session['id']);
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CoachScreen(sessionId: session['id']),
                                  ),
                                ).then((_) => _loadHistory());
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(color: AppColors.primaryNavy),
      child: Row(
        children: [
          const ParotMascot(state: ParotState.happy, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Sessions',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tap to continue a session',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs & Delete ───────────────────────────────────────────────────────

  Future<bool?> _showDeleteDialog(String id) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Simulation?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        content: Text(
          'This will permanently delete this simulation and all its messages.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    final originalList = List<Map<String, dynamic>>.from(
      _historySessionsNotifier.value,
    );
    final newList = List<Map<String, dynamic>>.from(originalList)
      ..removeWhere((s) => s['id'] == sessionId);

    _historySessionsNotifier.value = newList;

    try {
      await _supabase.deleteChatSession(sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Simulation deleted',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.primaryNavy,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete failed: $e");
      if (mounted) {
        _historySessionsNotifier.value = originalList;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting simulation',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
