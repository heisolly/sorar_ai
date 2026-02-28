import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/motion/smooth_fade_in.dart';
import '../../widgets/motion/pressable_scale.dart';
import '../../widgets/parot_mascot.dart';
import '../guided_simulation_screen.dart';
import '../../services/rizz_engine_service.dart';
import '../../theme/app_theme.dart';
import 'roast_me_screen.dart';

class ScenarioCardsScreen extends StatefulWidget {
  const ScenarioCardsScreen({super.key});

  @override
  State<ScenarioCardsScreen> createState() => _ScenarioCardsScreenState();
}

class _ScenarioCardsScreenState extends State<ScenarioCardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // ── Practice Pack Data ────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _packs = [
    {
      'id': 'rizz',
      'title': 'Rizz & Dating',
      'subtitle': 'Openings, momentum, and smooth exits.',
      'emoji': '💘',
      'tag': 'POPULAR',
      'tagColor': Color(0xFFFF8A80),
      'xp': '+150 XP',
      'difficulty': 2,
      'time': '3–6 min',
      'color': Color(0xFFFF8A80),
      'bgGradient': [Color(0xFFFFB2AB), Color(0xFFFF8A80)],
      'isDark': false,
      'locked': false,
      'parotState': 'happy',
      'featured': true,
    },
    {
      'id': 'roast_challenge',
      'title': 'Pickup Line Roast',
      'subtitle': 'Can you impress the AI? 3 chances.',
      'emoji': '🔥',
      'tag': 'CHALLENGE',
      'tagColor': AppColors.primaryBrand,
      'xp': '+200 XP',
      'difficulty': 3,
      'time': 'Quick',
      'color': AppColors.primaryBrand,
      'bgGradient': [Color(0xFFFF9E7D), AppColors.primaryBrand],
      'isDark': false,
      'locked': false,
      'parotState': 'encouraging',
      'featured': false,
    },
    {
      'id': 'awkward',
      'title': 'Awkward Moments',
      'subtitle': 'Recover gracefully. Keep your footing.',
      'emoji': '😬',
      'tag': 'FUN',
      'tagColor': Color(0xFFFFD54F),
      'xp': '+100 XP',
      'difficulty': 1,
      'time': '2–4 min',
      'color': Color(0xFFFFD54F),
      'bgGradient': [Color(0xFFFFE597), Color(0xFFFFD54F)],
      'isDark': false,
      'locked': false,
      'parotState': 'thinking',
      'featured': false,
    },
    {
      'id': 'conflict',
      'title': 'Conflict & Negotiation',
      'subtitle': 'Hold your ground without escalation.',
      'emoji': '🤝',
      'tag': 'SKILL',
      'tagColor': Color(0xFF81C784),
      'xp': '+175 XP',
      'difficulty': 3,
      'time': '4–7 min',
      'color': Color(0xFF81C784),
      'bgGradient': [Color(0xFFAEDFB2), Color(0xFF81C784)],
      'isDark': false,
      'locked': false,
      'parotState': 'encouraging',
      'featured': false,
    },
    {
      'id': 'power',
      'title': 'Power & Presence',
      'subtitle': 'Command the room. Advanced tier.',
      'emoji': '⚡',
      'tag': 'PREMIUM',
      'tagColor': AppColors.primaryNavy,
      'xp': '+300 XP',
      'difficulty': 3,
      'time': 'Unlimited',
      'color': AppColors.primaryNavy,
      'bgGradient': [Color(0xFF4A5568), AppColors.primaryNavy],
      'isDark': true,
      'locked': true,
      'parotState': 'happy',
      'featured': false,
    },
  ];

  final Map<String, List<Map<String, String>>> _scenarios = {
    'rizz': [
      {
        'context':
            'You are at a social gathering. You catch someone looking at you from across the room. They smile faintly.',
      },
      {
        'context':
            'You see someone cute waiting in line at a coffee shop. They are checking their phone. You are right behind them.',
      },
      {
        'context':
            'You are at a bar. Someone accidentally bumps into you and spills a bit of their drink. They look apologetic.',
      },
    ],
    'awkward': [
      {
        'context':
            'You waved at someone who didn\'t recognize you. A group of people saw it. They stare at you blankly.',
      },
      {
        'context':
            'You called your new boss "Mom" by accident during a meeting. The room goes silent.',
      },
      {
        'context':
            'You forgot someone\'s name immediately after being introduced. They ask, "So, you remember my name, right?"',
      },
    ],
    'conflict': [
      {
        'context':
            'You are in a team meeting presenting your idea. A colleague interrupts and dismisses your point. The room goes quiet.',
      },
      {
        'context':
            'A friend cancels plans on you last minute for the third time in a row. They text "Sorry something came up!".',
      },
      {
        'context':
            'You received a dish at a restaurant that is completely wrong. The waiter is walking by.',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _launch(Map<String, dynamic> pack) {
    if (pack['locked'] == true) {
      _showLockedDialog();
      return;
    }
    if (pack['id'] == 'roast_challenge') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoastMeScreen()),
      );
      return;
    }
    final modeId = pack['id'] as String;
    final scenarios = _scenarios[modeId] ?? [];
    String? ctx;
    if (scenarios.isNotEmpty) {
      ctx = scenarios[Random().nextInt(scenarios.length)]['context'];
    } else {
      ctx = pack['subtitle'];
    }
    final engine = RizzEngineService();
    final config = engine.createScenarioConfig(
      customContext: ctx,
      skillLevel: 'Intermediate',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuidedSimulationScreen(config: config)),
    );
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '🔒 Premium Pack',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        content: Text(
          'Upgrade to unlock Power & Presence and advanced techniques.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Maybe later',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Upgrade',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final featured = _packs.first;
    final packs = _packs.skip(1).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // ── Handraw decorations ───────────────────────────────────────────
          Positioned(
            top: 80,
            right: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.09,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_heart-fun.svg',
                  width: 100,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryNavy,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_spiral.svg',
                  width: 100,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryBrand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            right: -10,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: SvgPicture.asset(
                  'assets/handdraws/undraw_fun-arrow.svg',
                  width: 80,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryNavy,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Featured (Rizz & Dating) ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _buildFeaturedCard(featured),
                  ),
                ),

                // ── Real Life Simulator strip ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildRealLifeStrip(),
                  ),
                ),

                // ── Practice Packs label ────────────────────────────────────
                SliverToBoxAdapter(child: _buildPacksLabel()),

                // ── Pack cards ─────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildPackCard(packs[i], i),
                      ),
                      childCount: packs.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmoothFadeIn(
                  delay: const Duration(milliseconds: 50),
                  child: Text(
                    'Practice',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      height: 1.0,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                SmoothFadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Packs',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy.withValues(alpha: 0.6),
                      height: 1.0,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SmoothFadeIn(
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    'Level up your social game 🎮',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // XP summary badge
          SmoothFadeIn(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, _) => Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.04),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.primaryBrand.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBrand.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBrand,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '925',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'TOTAL XP',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
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

  // ── Featured card (Rizz & Dating) ─────────────────────────────────────────

  Widget _buildFeaturedCard(Map<String, dynamic> pack) {
    final colors = pack['bgGradient'] as List<Color>;
    final isDark = pack['isDark'] as bool;
    final textColor = isDark ? Colors.white : AppColors.primaryNavy;

    return SmoothFadeIn(
      delay: const Duration(milliseconds: 200),
      child: PressableScale(
        onPressed: () => _launch(pack),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.last.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -10,
                  top: -10,
                  child: Opacity(
                    opacity: 0.08,
                    child: SvgPicture.asset(
                      'assets/handdraws/undraw_heart-fun.svg',
                      width: 120,
                      colorFilter: ColorFilter.mode(colors.last, BlendMode.srcIn),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tag + XP row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    pack['tag'],
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    pack['xp'],
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              pack['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pack['subtitle'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.75),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Difficulty + time
                            Row(
                              children: [
                                _difficultyStars(
                                  pack['difficulty'] as int,
                                  textColor,
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pack['time'],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: textColor.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // CTA pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colors.last,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.last.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Enter simulation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mascot
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ParotMascot(state: ParotState.happy, size: 80),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${pack['emoji']} Let\'s go!',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
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

  // ── Real Life Simulator strip ──────────────────────────────────────────────

  Widget _buildRealLifeStrip() {
    return SmoothFadeIn(
      delay: const Duration(milliseconds: 280),
      child: PressableScale(
        onPressed: _launchRealRizzEngine,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎭', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Real Life Simulator',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrand.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FREE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBrand,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Unlimited, unpredictable scenarios. You set the scene.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Packs label ────────────────────────────────────────────────────────────

  Widget _buildPacksLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        children: [
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
            'ALL PRACTICE PACKS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            '${_packs.length} packs',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pack card ──────────────────────────────────────────────────────────────

  Widget _buildPackCard(Map<String, dynamic> pack, int index) {
    final isLocked = pack['locked'] == true;
    final color = pack['color'] as Color;
    final colors = pack['bgGradient'] as List<Color>;

    return SmoothFadeIn(
      delay: Duration(milliseconds: 300 + (index * 80)),
      child: PressableScale(
        onPressed: () => _launch(pack),
        child: Container(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLocked ? AppColors.border : AppColors.border,
              width: 1.5,
            ),
            boxShadow: isLocked
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Accent bar left
                if (!isLocked)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isLocked
                              ? AppColors.border
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isLocked
                              ? []
                              : [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(
                            isLocked ? '🔒' : pack['emoji'],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pack['title'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isLocked
                                          ? AppColors.textDisabled
                                          : AppColors.primaryNavy,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isLocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pack['xp'],
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pack['subtitle'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isLocked
                                    ? AppColors.textDisabled
                                    : AppColors.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Bottom row: difficulty + time + tag
                            Row(
                              children: [
                                if (!isLocked) ...[
                                  _difficultyStars(
                                    pack['difficulty'] as int,
                                    AppColors.primaryNavy,
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    pack['time'],
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pack['tag'],
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: AppColors.textDisabled,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Upgrade to unlock',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Mascot or arrow
                      if (!isLocked)
                        _buildMiniMascot(pack)
                      else
                        const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: AppColors.textDisabled,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
  }

  Widget _buildMiniMascot(Map<String, dynamic> pack) {
    final stateStr = pack['parotState'] as String;
    ParotState state;
    switch (stateStr) {
      case 'encouraging':
        state = ParotState.encouraging;
        break;
      case 'thinking':
        state = ParotState.thinking;
        break;
      default:
        state = ParotState.happy;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [ParotMascot(state: state, size: 40)],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _difficultyStars(int count, Color baseColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(
          i < count ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: i < count
              ? AppColors.primaryBrand
              : baseColor.withValues(alpha: 0.2),
        );
      }),
    );
  }

  // ── Real Rizz Engine dialog ────────────────────────────────────────────────

  void _launchRealRizzEngine() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, anim1, anim2) {
        final controller = TextEditingController();
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mascot + title
                  const ParotMascot(state: ParotState.encouraging, size: 70),
                  const SizedBox(height: 16),
                  Text(
                    'Set the Stage',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Define any social challenge and let Parot guide you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. My friend is upset about a secret I accidentally shared…',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textDisabled,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            Navigator.pop(context);
                            final engine = RizzEngineService();
                            final config = engine.createScenarioConfig(
                              customContext: text.isNotEmpty ? text : null,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GuidedSimulationScreen(config: config),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Start Simulation',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
