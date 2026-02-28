import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_motion.dart';
import '../../widgets/motion/smooth_fade_in.dart';
import '../../widgets/motion/pressable_scale.dart';
import '../../services/ai_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parot_mascot.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROAST ME SCREEN  —  Gamified, addictive, fun
// ─────────────────────────────────────────────────────────────────────────────

class RoastMeScreen extends StatefulWidget {
  const RoastMeScreen({super.key});

  @override
  State<RoastMeScreen> createState() => _RoastMeScreenState();
}

class _RoastMeScreenState extends State<RoastMeScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final SupabaseService _supabaseService = SupabaseService();

  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _xpBarCtrl;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _xpAnim;

  // ── Game State ─────────────────────────────────────────────────────────────
  int _chancesLeft = 3;
  bool _isLoading = false;
  bool _hasStarted = false;
  bool _isTyping = false;
  bool _gameOver = false;
  bool _victory = false;
  bool _showConfetti = false;

  // ── AI Result State ────────────────────────────────────────────────────────
  String? _aiReactionStr;
  String? _aiResponse;
  String? _aiFeedback;
  Map<String, dynamic>? _aiScores;
  String? _aiRizzRating;
  String? _aiBetterLine;

  // ── Score tracking ─────────────────────────────────────────────────────────
  double _totalXp = 0;
  double _currentRoundXp = 0;
  final List<Map<String, dynamic>> _history = [];
  String? _sessionId;
  bool _isFocusing = false;

  // ── Derived UI ────────────────────────────────────────────────────────────
  ParotState get _parotState {
    if (_isLoading) return ParotState.thinking;
    if (_victory) return ParotState.celebrating;
    if (_gameOver) return ParotState.oops;
    if (_isTyping) return ParotState.thinking;
    if (!_hasStarted) return ParotState.waving;
    final charm = (_aiScores?['charm'] ?? 3) as num;
    if (charm >= 4) return ParotState.celebrating;
    if (charm <= 2) return ParotState.confused;
    return ParotState.encouraging;
  }

  // Duolingo Palette
  // Refined Soft Palette (More Premium, less 'loud')
  static const Color duoGreen = Color(0xFF5AC3B6); // Soft Tiffany/Mint
  static const Color duoRed = Color(0xFFFF8A80); // Soft Coral Red
  static const Color duoBlue = Color(0xFF7CB9E8); // Soft Sky Blue
  static const Color duoYellow = Color(0xFFFFD54F); // Soft Sunflower Yellow
  static const Color duoOrange = Color(0xFFFFB347); // Soft Pastel Orange
  static const Color duoWhite = Color(0xFFFFFFFF);
  static const Color duoBg = Color(0xFFF9FAFB); // Ultra Clean Off-White
  static const Color duoText = Color(0xFF2D3748); // Deep Slate
  static const Color duoLightText = Color(0xFF718096); // Slate Grey

  Color get _arenaColor {
    if (_victory) return duoGreen.withValues(alpha: 0.1);
    if (_gameOver) return duoRed.withValues(alpha: 0.1);
    return duoBg;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _xpBarCtrl = AnimationController(vsync: this, duration: AppMotion.kSlow);
    _xpAnim = Tween<double>(begin: 0, end: 0).animate(_xpBarCtrl);

    _controller.addListener(() {
      final typing = _controller.text.isNotEmpty;
      if (_isTyping != typing) setState(() => _isTyping = typing);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _confettiCtrl.dispose();
    _xpBarCtrl.dispose();
    super.dispose();
  }

  // ── Session ────────────────────────────────────────────────────────────────
  Future<void> _initSession() async {
    if (_sessionId != null) return;
    try {
      final session = await _supabaseService.createChatSession(
        additionalData: {
          'metadata': {
            'scenario_type': 'Roast Me',
            'started_at': DateTime.now().toIso8601String(),
          },
        },
      );
      _sessionId = session['id'];
    } catch (e) {
      debugPrint('Session error: $e');
    }
  }

  // ── Game Logic ─────────────────────────────────────────────────────────────
  void _submitLine() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Duplicate check
    if (_history.any(
      (h) =>
          h['role'] == 'user' &&
          h['content'].toString().trim().toLowerCase() ==
              text.trim().toLowerCase(),
    )) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Already used that one! Be original 😏',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryBrand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    _focusNode.unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _hasStarted = true;
      _showConfetti = false;
      _aiReactionStr = null;
      _aiScores = null;
    });

    await _initSession();
    _history.add({'role': 'user', 'content': text});

    if (_sessionId != null) {
      await _supabaseService.addChatMessage(
        sessionId: _sessionId!,
        sender: 'user',
        content: text,
      );
    }

    final historyForAi = _history
        .map(
          (h) => {
            'role': h['role'] as String,
            'content': h['content'] as String,
          },
        )
        .toList();

    try {
      final result = await _aiService.getPickupLineFeedback(
        pickupLine: text,
        history: historyForAi,
      );

      if (!mounted) return;

      // Compute XP earned this round
      final charm = (result['scores']?['charm'] ?? 3) as num;
      final originality = (result['scores']?['originality'] ?? 3) as num;
      final confidence = (result['scores']?['confidence'] ?? 3) as num;
      final avg = (charm + originality + confidence) / 3;
      final earned = (avg / 5 * 100).clamp(0.0, 100.0);

      // Animate XP bar
      final prevTotal = _totalXp;
      final newTotal = (_totalXp + earned).clamp(0.0, 300.0);
      _xpAnim = Tween<double>(
        begin: prevTotal / 300,
        end: newTotal / 300,
      ).animate(CurvedAnimation(parent: _xpBarCtrl, curve: Curves.easeOut));
      _xpBarCtrl.forward(from: 0);

      setState(() {
        _isLoading = false;
        _chancesLeft--;
        _aiReactionStr = result['reaction'];
        _aiResponse = result['response'];
        _aiFeedback = result['feedback'];
        _aiScores = result['scores'];
        _aiRizzRating = result['rizz_rating'];
        _aiBetterLine = result['better_line'];
        _currentRoundXp = earned;
        _totalXp = newTotal;

        _history.add({'role': 'assistant', 'content': _aiResponse ?? ''});
        _controller.clear();
        _isTyping = false;
        _isFocusing = false;

        if (charm >= 4) {
          _showConfetti = true;
          _confettiCtrl.forward(from: 0);
        } else if (charm <= 2) {
          _shakeCtrl.forward(from: 0);
        }

        HapticFeedback.lightImpact();

        if (_chancesLeft <= 0) {
          _gameOver = true;
          // Victory if avg is decent and mascot was happy
          _victory = avg >= 3.0; // Loosened for fun
        }
      });

      // Scroll to top after judgment to see the verdict
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });

      if (_sessionId != null) {
        await _supabaseService.addChatMessage(
          sessionId: _sessionId!,
          sender: 'ai',
          content: _aiResponse,
          feedback: {
            'reaction': _aiReactionStr,
            'feedback': _aiFeedback,
            'scores': _aiScores,
          },
        );
      }
    } catch (e) {
      debugPrint('Game loop error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetGame() {
    HapticFeedback.heavyImpact();
    setState(() {
      _chancesLeft = 3;
      _history.clear();
      _hasStarted = false;
      _aiReactionStr = null;
      _aiResponse = null;
      _aiFeedback = null;
      _aiScores = null;
      _aiRizzRating = null;
      _aiBetterLine = null;
      _showConfetti = false;
      _sessionId = null;
      _totalXp = 0;
      _currentRoundXp = 0;
      _gameOver = false;
      _victory = false;
    });
    _xpBarCtrl.reset();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _arenaColor,
      resizeToAvoidBottomInset: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: _arenaColor,
        child: Stack(
          children: [
            // ── BG grid texture ─────────────────────────────────────────────
            Positioned.fill(child: _buildGridTexture()),

            // ── Handraw decorations ─────────────────────────────────────────
            Positioned(
              top: 90,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.06,
                  child: SvgPicture.asset(
                    'assets/handdraws/undraw_spiral.svg',
                    width: 120,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -10,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: SvgPicture.asset(
                    'assets/handdraws/undraw_exclamation-point.svg',
                    width: 80,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),

            // ── Confetti ────────────────────────────────────────────────────
            if (_showConfetti) _buildConfetti(),

            // ── Main content ────────────────────────────────────────────────
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildTopBar(), _buildXpBar()],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                    child: _gameOver
                        ? _buildEndScreen()
                        : !_hasStarted
                        ? _buildIntroState()
                        : _buildGameState(),
                  ),
                ),
                if (!_gameOver) _buildInputPanel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Back button (Duolingo style - simple cross)
          PressableScale(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: duoLightText,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // XP Bar (Chunky Duolingo style)
          Expanded(child: _buildXpBar()),

          const SizedBox(width: 12),

          // Lives (flame hearts)
          Row(
            children: List.generate(3, (i) {
              final active = i < _chancesLeft;
              return AnimatedSwitcher(
                duration: AppMotion.kMedium,
                child: Padding(
                  key: ValueKey('$i-$active'),
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    active ? '❤️' : '🖤',
                    style: TextStyle(
                      fontSize: 22,
                      color: active
                          ? null
                          : duoLightText.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── XP Bar ────────────────────────────────────────────────────────────────
  Widget _buildXpBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 16,
            width: double.infinity,
            color: const Color(0xFFE5E5E5),
            child: AnimatedBuilder(
              animation: _xpAnim,
              builder: (_, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _xpAnim.value,
                child: Container(
                  decoration: const BoxDecoration(color: duoGreen),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroState() {
    return Center(
      key: const ValueKey('intro'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mascot
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + (_pulseCtrl.value * 0.05),
                child: child,
              ),
              child: ParotMascot(state: ParotState.waving, size: 140),
            ),

            const SizedBox(height: 32),

            // Speech Bubble Style Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFE5E5E5),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'PICKUP LINE ROAST',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: duoText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try to impress me with your best rizz!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: duoLightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Stats preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _introStat('✨', 'Charm'),
                _introStat('🎯', 'Originality'),
                _introStat('💪', 'Confidence'),
              ],
            ),

            const SizedBox(height: 40),

            Text(
              'Type below to begin',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: duoLightText,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introStat(String emoji, String label) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: duoWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE5E5E5),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.fredoka(
              fontSize: 10,
              color: duoText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameState() {
    return SingleChildScrollView(
      key: const ValueKey('game'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Mascot area
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final shake = sin(_shakeAnim.value * pi * 8) * 8;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _isLoading ? 1.0 + (_pulseCtrl.value * 0.06) : 1.0,
                    child: child,
                  ),
                  child: ParotMascot(state: _parotState, size: 130),
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: duoWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFE5E5E5),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: duoBlue,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'JUDGING YOUR RIZZ...',
                          style: GoogleFonts.fredoka(
                            color: duoText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 30),

          // RESULTS AREA
          if (!_isLoading && _aiReactionStr != null) ...[
            // Verdict Badge
            SmoothFadeIn(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _verdictColor(_aiScores),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _verdictColor(_aiScores).withValues(alpha: 0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  (_aiReactionStr ?? '').toUpperCase(),
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // AI Response Speech Bubble
            SmoothFadeIn(
              delay: const Duration(milliseconds: 100),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: duoWhite,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFE5E5E5),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _aiResponse ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: duoText,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _aiFeedback ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: duoLightText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rizz Review Section (Fun Rating & Suggestion)
            if (_aiRizzRating != null) ...[
              SmoothFadeIn(
                delay: const Duration(milliseconds: 150),
                child: Column(
                  children: [
                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: duoYellow,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: duoOrange, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: duoOrange,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _aiRizzRating!.toUpperCase(),
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: duoOrange.withValues(alpha: 0.5),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_aiBetterLine != null) ...[
                      const SizedBox(height: 16),
                      // "Try this instead" card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5E5E5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TRY THIS INSTEAD:',
                              style: GoogleFonts.fredoka(
                                fontSize: 11,
                                color: duoBlue,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '"$_aiBetterLine"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 17,
                                color: duoText,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Score cards
            if (_aiScores != null)
              SmoothFadeIn(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    _buildScoreCard('✨', 'CHARM', _aiScores!['charm'], duoBlue),
                    const SizedBox(width: 12),
                    _buildScoreCard(
                      '🎯',
                      'ORIG.',
                      _aiScores!['originality'],
                      duoOrange,
                    ),
                    const SizedBox(width: 12),
                    _buildScoreCard(
                      '💪',
                      'BOLD',
                      _aiScores!['confidence'],
                      duoGreen,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // XP earned badge
            if (_currentRoundXp > 0)
              SmoothFadeIn(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: duoYellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE5A100),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '+${_currentRoundXp.toInt()} XP earned!',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: duoText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 100),
          ],

          if (_isLoading) const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    String emoji,
    String label,
    dynamic score,
    Color color,
  ) {
    int s = 0;
    if (score is int) s = score;
    if (score is double) s = score.toInt();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: duoWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE5E5E5),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            // Duolingo Style chunky score dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < s ? color : const Color(0xFFE5E5E5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 10,
                color: duoLightText,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── End Screen ─────────────────────────────────────────────────────────────
  Widget _buildEndScreen() {
    return Center(
      key: const ValueKey('end'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + (_pulseCtrl.value * 0.08),
                child: child,
              ),
              child: ParotMascot(state: _parotState, size: 150),
            ),

            const SizedBox(height: 32),

            // Results Badge Big
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: duoWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _victory ? duoGreen : duoRed,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _victory ? duoGreen : duoRed,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _victory ? 'IMPRESSIVE!' : 'OOF, ROASTED',
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      color: _victory ? duoGreen : duoRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _victory
                        ? 'You officially have rizz! 🎉'
                        : 'Better luck next time, champ.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: duoText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _endStat('⚡', '${_totalXp.toInt()}', 'TOTAL XP'),
                _endStat('📅', '${3 - _chancesLeft}', 'TURNS'),
                _endStat(
                  _victory ? '🎯' : '💀',
                  _victory ? 'WIN' : 'LOSE',
                  'OUTCOME',
                ),
              ],
            ),

            const SizedBox(height: 60),

            // PLAY AGAIN BUTTON
            PressableScale(
              onPressed: _resetGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: duoBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF1899D6),
                      offset: Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'PLAY AGAIN',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    color: duoWhite,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'EXIT TO PACKS',
                style: GoogleFonts.fredoka(
                  color: duoLightText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _endStat(String emoji, String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: duoWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE5E5E5),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: duoText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 10,
              color: duoLightText,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: duoWhite,
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mascot avatar (smaller)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ParotMascot(
                state: _isTyping ? ParotState.thinking : ParotState.idle,
                size: 40,
              ),
            ),
            const SizedBox(width: 12),

            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isFocusing ? duoBlue : const Color(0xFFE5E5E5),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: duoText,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: duoBlue,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitLine(),
                  onTap: () => setState(() => _isFocusing = true),
                  onTapOutside: (_) {
                    _focusNode.unfocus();
                    setState(() => _isFocusing = false);
                  },
                  onEditingComplete: () {
                    _focusNode.unfocus();
                    setState(() => _isFocusing = false);
                  },
                  decoration: InputDecoration(
                    hintText: 'Drop your best line...',
                    hintStyle: GoogleFonts.nunito(
                      color: duoLightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            PressableScale(
              onPressed: (_isLoading || _controller.text.isEmpty)
                  ? null
                  : _submitLine,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (_isLoading || _controller.text.isEmpty)
                      ? const Color(0xFFE5E5E5)
                      : duoBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (_isLoading || _controller.text.isEmpty)
                      ? []
                      : const [
                          BoxShadow(
                            color: Color(0xFF1899D6),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildGridTexture() {
    return CustomPaint(painter: _GridPainter());
  }

  Color _verdictColor(Map<String, dynamic>? scores) {
    if (scores == null) return duoBlue;
    final charm = (scores['charm'] ?? 3) as num;
    if (charm >= 4) return duoGreen;
    if (charm <= 2) return duoRed;
    return duoYellow; // Changed from Orange to Yellow for a softer mid-state
  }

  Widget _buildConfetti() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, _) {
            if (_confettiCtrl.value > 0.9) return const SizedBox.shrink();
            return Stack(
              children: List.generate(20, (i) {
                final rng = Random(i);
                final x = rng.nextDouble() * MediaQuery.of(context).size.width;
                final speed = 0.3 + rng.nextDouble() * 0.7;
                final top =
                    _confettiCtrl.value *
                    speed *
                    MediaQuery.of(context).size.height;
                final emoji = ['🎉', '⭐', '💥', '✨', '🔥', '💘'][i % 6];
                return Positioned(
                  left: x,
                  top: top,
                  child: Opacity(
                    opacity: (1 - _confettiCtrl.value).clamp(0.0, 1.0),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 18 + rng.nextDouble() * 12),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E5E5).withValues(alpha: 0.4)
      ..strokeWidth = 1.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
