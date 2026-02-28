import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parot_ai/theme/app_theme.dart';
import 'dart:math' as math;

enum ParotState {
  idle,
  listening,
  talking,
  happy,
  encouraging,
  thinking,
  confused,
  celebrating,
  sleepy,
  teacher,
  grateful,
  study,
  waving,
  oops,
  sympathy,
  loading,
  winner,
  focused,
  singing,
  cool,
  sad,
  excited,
  proud,
  alert,
  male,
  female,
  ageTeens,
  age20s,
  age40s,
  age60s,
  ageSenior,
  anxious,
  blowing,
  explaining,
  pointingUp,
  pointingDown,
  pointingLeft,
  pointingRight,
}

class ParotMascot extends StatefulWidget {
  final ParotState state;
  final double size;
  final bool shouldAnimate;
  final Color? customColor;
  final double opacity;
  final bool isDecorative;
  final bool bounce;

  const ParotMascot({
    super.key,
    this.state = ParotState.idle,
    this.size = 240, // Increased default size
    this.shouldAnimate = true,
    this.customColor,
    this.opacity = 1.0,
    this.isDecorative = false,
    this.bounce = true,
  });

  /// Factory to get mascot state from a mood value (0-100)
  factory ParotMascot.fromMood({
    Key? key,
    required double moodValue,
    double size = 240, // Increased default size
    bool animate = true,
  }) {
    ParotState state;
    if (moodValue >= 90) {
      state = ParotState.excited;
    } else if (moodValue >= 75) {
      state = ParotState.happy;
    } else if (moodValue >= 60) {
      state = ParotState.proud;
    } else if (moodValue >= 45) {
      state = ParotState.idle;
    } else if (moodValue >= 30) {
      state = ParotState.thinking;
    } else if (moodValue >= 15) {
      state = ParotState.confused;
    } else {
      state = ParotState.sad;
    }

    return ParotMascot(
      key: key,
      state: state,
      size: size,
      shouldAnimate: animate,
    );
  }

  @override
  State<ParotMascot> createState() => _ParotMascotState();
}

class _ParotMascotState extends State<ParotMascot>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _blinkController;
  late AnimationController
  _mascotPulseController; // Renamed to avoid collisions
  bool _isBlinking = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _mascotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.shouldAnimate) {
      _breathingController.repeat(reverse: true);
      _mascotPulseController.repeat(reverse: true);
    }

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Faster, snappier blink
    );

    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (mounted) setState(() => _isBlinking = false);
        _scheduleNextBlink();
      }
    });

    if (widget.shouldAnimate) {
      _scheduleNextBlink();
    }
  }

  void _scheduleNextBlink() {
    if (!mounted || !widget.shouldAnimate) return;
    // Randomize blink interval for more natural feel (2-6 seconds)
    final delay = 2000 + _random.nextInt(4000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && widget.shouldAnimate) {
        setState(() => _isBlinking = true);
        _blinkController.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(ParotMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate != oldWidget.shouldAnimate ||
        widget.bounce != oldWidget.bounce) {
      if (widget.shouldAnimate) {
        _breathingController.repeat(reverse: true);
        _mascotPulseController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _mascotPulseController.stop();
      }

      if (widget.shouldAnimate && !oldWidget.shouldAnimate) {
        _scheduleNextBlink();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _blinkController.dispose();
    _mascotPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathingController,
        _mascotPulseController,
      ]),
      builder: (context, child) {
        // Subtle scaling effect
        final scale = 1.0 + (0.02 * _mascotPulseController.value);

        // Squish effect for breathing
        final squishX = 1.0 + (0.02 * _breathingController.value);
        final squishY = 1.0 - (0.02 * _breathingController.value);

        return Opacity(
          opacity: widget.opacity,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(0, 0, scale * squishX)
              ..setEntry(1, 1, scale * squishY)
              ..setEntry(
                1,
                3,
                widget.bounce ? -8 * _breathingController.value : 0.0,
              ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: SvgPicture.string(
                _getSvgString(widget.state),
                key: ValueKey(widget.state),
                width: widget.size,
                height: widget.size,
                placeholderBuilder: (context) =>
                    SizedBox(width: widget.size, height: widget.size),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSvgString(ParotState state) {
    // Colors from AppTheme
    String colorToHex(Color color) {
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }

    final String orange = colorToHex(AppColors.primaryBrand);
    final String orangeDark = colorToHex(
      AppColors.primaryBrand.withValues(alpha: 0.8),
    );
    final String navy = colorToHex(AppColors.primaryNavy);
    final String white = '#FFFFFF';
    final String red = colorToHex(AppColors.warning);
    final String yellow = colorToHex(AppColors.parotYellow);
    final String blue = '#64B5F6';

    final double mouthVal = widget.shouldAnimate
        ? _breathingController.value
        : 0.0;

    // Common gradient and glow definitions
    final String defs =
        '''
      <defs>
        <linearGradient id="bodyGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:$orange;stop-opacity:1" />
          <stop offset="100%" style="stop-color:$orangeDark;stop-opacity:1" />
        </linearGradient>
      </defs>
    ''';

    // Decorative mode uses a single color silhouette
    if (widget.isDecorative) {
      final String decorColor = widget.customColor != null
          ? colorToHex(widget.customColor!)
          : orange;
      return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
        <circle cx="100" cy="110" fill="$decorColor" r="70" opacity="0.3" />
        <circle cx="100" cy="80" fill="$decorColor" r="50" opacity="0.2" />
      </svg>''';
    }

    final String blinkingEyes =
        '''
      <path d="M88 80 H112" stroke="$navy" stroke-width="5" stroke-linecap="round" />
    ''';

    final String normalEyes =
        '''
      <circle cx="100" cy="80" fill="$white" r="13" stroke="$navy" stroke-width="6" />
      <circle cx="100" cy="80" fill="$navy" r="5" />
    ''';

    final String currentEyes = _isBlinking ? blinkingEyes : normalEyes;

    switch (state) {
      case ParotState.idle:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 ${130 + (4 * mouthVal)} 140 100 C140 70 160 90 160 90" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
        </svg>''';

      case ParotState.listening:
        final String blinkEye =
            '<path d="M98 70 H122" stroke="$navy" stroke-width="5" stroke-linecap="round" />';
        final String normalEye =
            '''
          <circle cx="110" cy="70" fill="$white" r="14" stroke="$navy" stroke-width="6" />
          <circle cx="110" cy="70" fill="$navy" r="5" />
        ''';
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <g transform="rotate(6 100 100)">
            <circle cx="100" cy="100" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
            <path d="M110 120 C110 120 150 ${140 + (4 * mouthVal)} 150 110 C150 80 170 100 170 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
            <path d="M90 60 L70 80 L90 100" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
            ${_isBlinking ? blinkEye : normalEye}
          </g>
        </svg>''';

      case ParotState.talking:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 ${130 + (8 * mouthVal)} 140 100 C140 70 160 90 160 90" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 65 L55 85 L80 85" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M80 95 L65 95 L80 115" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
        </svg>''';

      case ParotState.happy:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M140 60 C140 60 160 80 140 110" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Winder, warmer smile -->
          <path d="M90 85 Q105 ${100 + (4 * mouthVal)} 120 85" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          ${_isBlinking ? '<path d="M95 72 H115" stroke="$navy" stroke-width="4" stroke-linecap="round" />' : '<path d="M95 75 Q100 70 105 75" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="3" />'}
        </svg>''';

      case ParotState.encouraging:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M90 130 Q130 ${150 + (6 * mouthVal)} 150 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          ${_isBlinking ? '<path d="M90 75 H110" stroke="$navy" stroke-width="4" stroke-linecap="round" />' : '<path d="M90 80 Q100 85 110 80" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="6" />'}
        </svg>''';

      case ParotState.thinking:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 ${130 + (4 * mouthVal)} 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <circle cx="150" cy="50" fill="$navy" r="4" />
          <circle cx="165" cy="40" fill="$navy" r="5" />
        </svg>''';

      case ParotState.confused:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <g transform="rotate(-6 100 110)">
            <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
            <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
            <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
            <circle cx="100" cy="80" fill="$white" r="12" stroke="$navy" stroke-width="6" />
            <circle cx="100" cy="80" fill="$navy" r="2" />
            <path d="M140 40 Q150 20 160 40 Q160 60 150 60" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="6" />
            <circle cx="150" cy="75" fill="$navy" r="4" />
          </g>
        </svg>''';

      case ParotState.celebrating:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M140 80 L170 50" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M60 140 L30 110" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          ${_isBlinking ? '<path d="M90 80 H110" stroke="$navy" stroke-width="5" stroke-linecap="round" />' : '<path d="M100 70 L105 82 L115 82 L107 89 L110 100 L100 94 L90 100 L93 89 L85 82 L95 82 Z" fill="$white" stroke="$navy" stroke-width="3" />'}
        </svg>''';

      case ParotState.sleepy:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 75 L60 95 L80 115" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M95 85 H115" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M150 40 L160 40 L150 50 L160 50" stroke="$navy" stroke-linecap="round" stroke-width="4" />
        </svg>''';

      case ParotState.teacher:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <circle cx="100" cy="80" fill="$white" r="13" stroke="$navy" stroke-width="6" />
          <circle cx="100" cy="80" fill="$navy" r="5" />
          <circle cx="100" cy="80" r="18" stroke="$navy" stroke-width="4" />
          <path d="M82 80 L60 85" stroke="$navy" stroke-width="4" />
        </svg>''';

      case ParotState.grateful:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <path d="M140 50 L145 45 C148 42 152 42 155 45 C158 48 158 52 155 55 L140 70" fill="$red" stroke="$navy" stroke-width="3" />
        </svg>''';

      case ParotState.study:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <rect fill="$white" height="30" stroke="$navy" stroke-width="4" transform="rotate(-10 130 125)" width="40" x="110" y="110" />
          <path d="M110 110 L150 110" stroke="$navy" stroke-width="4" transform="rotate(-10 130 125)" />
        </svg>''';

      case ParotState.waving:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M140 70 C150 50 170 50 180 70" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <path d="M185 60 L195 50" stroke="$navy" stroke-width="4" />
        </svg>''';

      case ParotState.oops:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <ellipse cx="100" cy="120" fill="url(#bodyGradient)" rx="75" ry="60" stroke="$navy" stroke-width="6" />
          <path d="M100 120 C100 120 140 140 140 110" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 80 L60 100 L80 120" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M95 85 L105 95 M105 85 L95 95" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M140 50 Q145 60 140 70 Q135 60 140 50" fill="$blue" stroke="$navy" stroke-width="3" />
        </svg>''';

      case ParotState.sympathy:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 80 L60 100 L80 120" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M95 90 Q105 85 115 90" stroke="$navy" stroke-linecap="round" stroke-width="6" />
        </svg>''';

      case ParotState.loading:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M90 70 C100 60 115 70 110 80 C105 90 90 80 90 70" stroke="$navy" stroke-width="4" />
        </svg>''';

      case ParotState.winner:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <path d="M130 110 L140 100 L150 110" fill="$yellow" stroke="$navy" stroke-width="4" />
          <path d="M135 120 L135 140 M145 120 L145 140" stroke="$navy" stroke-width="3" />
        </svg>''';

      case ParotState.focused:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M95 75 L115 80" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <rect fill="$red" height="10" stroke="$navy" stroke-width="3" width="40" x="90" y="55" />
        </svg>''';

      case ParotState.singing:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 60 L55 80 L80 80" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M80 90 L65 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <circle cx="100" cy="75" fill="$white" r="13" stroke="$navy" stroke-width="6" />
          <circle cx="100" cy="75" fill="$navy" r="5" />
          <path d="M150 50 L150 70 M150 50 L165 45" stroke="$navy" stroke-width="4" />
          <circle cx="145" cy="75" fill="$navy" r="5" />
        </svg>''';

      case ParotState.cool:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M95 75 H125 L120 90 H100 Z" fill="$navy" stroke="$navy" stroke-width="2" />
          <path d="M95 78 H125" opacity="0.5" stroke="$white" stroke-width="2" />
        </svg>''';

      case ParotState.sad:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 130 Q100 110 120 130" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 80 L60 100 L80 120" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <path d="M110 80 Q120 75 130 80" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="4" />
          <circle cx="120" cy="95" fill="$blue" r="4" />
        </svg>''';

      case ParotState.excited:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 130 Q100 160 120 130 Z" fill="$white" stroke="$navy" stroke-width="6" />
          <path d="M70 70 L90 90 M90 70 L70 90" stroke="$navy" stroke-width="6" stroke-linecap="round" />
          <path d="M110 70 L130 90 M130 70 L110 90" stroke="$navy" stroke-width="6" stroke-linecap="round" />
          <path d="M40 70 L20 50 M160 70 L180 50" stroke="$navy" stroke-width="6" stroke-linecap="round" />
        </svg>''';

      case ParotState.proud:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M80 130 Q100 140 120 130" fill="none" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M70 80 Q85 70 100 80 Q115 70 130 80" fill="none" stroke="$navy" stroke-width="6" stroke-linecap="round" />
          <path d="M40 140 L20 160 M160 140 L180 160" stroke="$navy" stroke-width="8" stroke-linecap="round" />
        </svg>''';

      case ParotState.alert:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <circle cx="80" cy="80" fill="$white" r="15" stroke="$navy" stroke-width="6" />
          <circle cx="120" cy="80" fill="$white" r="15" stroke="$navy" stroke-width="6" />
          <circle cx="80" cy="80" fill="$navy" r="6" />
          <circle cx="120" cy="80" fill="$navy" r="6" />
          <path d="M90 130 H110" stroke="$navy" stroke-width="8" stroke-linecap="round" />
        </svg>''';

      case ParotState.male:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <!-- Shirt Collar -->
          <path d="M75 165 L100 175 L125 165" fill="$white" stroke="$navy" stroke-width="4" stroke-linejoin="round" />
          <!-- Tie -->
          <path d="M100 175 L85 200 L100 215 L115 200 Z" fill="$navy" stroke="$navy" stroke-width="2" />
          <rect x="94" y="175" width="12" height="8" fill="$navy" rx="2" />
        </svg>''';

      case ParotState.female:
        final String lashEyes =
            '''
          <circle cx="100" cy="80" fill="$white" r="13" stroke="$navy" stroke-width="6" />
          <circle cx="100" cy="80" fill="$navy" r="5" />
          <path d="M114 74 L124 66 M116 80 L126 76" stroke="$navy" stroke-width="3" stroke-linecap="round" />
        ''';
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          ${_isBlinking ? blinkingEyes : lashEyes}
          <!-- Larger Bow -->
          <g transform="translate(145, 65) rotate(15)">
            <path d="M0 0 L-25 -15 L-25 15 Z" fill="#FF4081" stroke="$navy" stroke-width="3" />
            <path d="M0 0 L25 -15 L25 15 Z" fill="#FF4081" stroke="$navy" stroke-width="3" />
            <circle cx="0" cy="0" fill="#FF4081" r="6" stroke="$navy" stroke-width="3" />
          </g>
        </svg>''';

      case ParotState.ageTeens:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <circle cx="100" cy="80" fill="$white" r="16" stroke="$navy" stroke-width="6" />
          <circle cx="100" cy="80" fill="$navy" r="6" />
          <!-- Baseball Cap -->
          <path d="M60 60 Q100 30 140 60 L145 75 L55 75 Z" fill="$navy" />
          <path d="M140 60 L170 80 L165 85 L140 70" fill="$navy" />
        </svg>''';

      case ParotState.age20s:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
        </svg>''';

      case ParotState.age40s:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <!-- Professional Glasses -->
          <rect x="75" y="70" width="50" height="20" fill="none" stroke="$navy" stroke-width="3" rx="4" />
          <path d="M75 80 H60 M125 80 H140" stroke="$navy" stroke-width="2" />
        </svg>''';

      case ParotState.age60s:
        final String glassEyes =
            '''
          <circle cx="85" cy="80" r="15" fill="none" stroke="$navy" stroke-width="3" />
          <circle cx="115" cy="80" r="15" fill="none" stroke="$navy" stroke-width="3" />
          <path d="M100 80 H100" stroke="$navy" stroke-width="3" />
        ''';
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          ${_isBlinking ? currentEyes : glassEyes}
          <!-- Graying Beard/Stubble -->
          <path d="M60 140 Q100 185 140 140" fill="none" stroke="#BDC3C7" stroke-width="8" stroke-dasharray="2 4" />
        </svg>''';

      case ParotState.ageSenior:
        final String seniorEyes =
            '''
          <circle cx="85" cy="80" r="18" fill="none" stroke="$navy" stroke-width="3" />
          <circle cx="115" cy="80" r="18" fill="none" stroke="$navy" stroke-width="3" />
        ''';
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          ${_isBlinking ? currentEyes : seniorEyes}
          <!-- White Hair/Moustache -->
          <path d="M60 70 Q100 20 140 70" fill="none" stroke="#ECF0F1" stroke-width="12" stroke-linecap="round" />
          <path d="M90 120 Q100 135 110 120" fill="none" stroke="#ECF0F1" stroke-width="8" stroke-linecap="round" />
          <!-- Cane (Partial) -->
          <path d="M160 140 L160 200" stroke="$navy" stroke-width="6" stroke-linecap="round" />
          <path d="M160 140 Q170 120 185 130" fill="none" stroke="$navy" stroke-width="6" />
        </svg>''';

      case ParotState.blowing:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <!-- Small O mouth for blowing -->
          <circle cx="100" cy="120" r="10" fill="$white" stroke="$navy" stroke-width="4" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          $currentEyes
          <!-- Breath lines (blowing right) -->
          <path d="M120 120 L150 120 M120 110 L145 105 M120 130 L145 135" stroke="$navy" stroke-width="3" stroke-linecap="round" opacity="0.6" />
        </svg>''';

      case ParotState.explaining:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 ${130 + (8 * mouthVal)} 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Explaining wing -->
          <path d="M140 110 Q160 80 150 60" fill="none" stroke="$navy" stroke-width="8" stroke-linecap="round" />
          <path d="M150 60 L145 70 M150 60 L160 70" stroke="$navy" stroke-width="4" stroke-linecap="round" />
          $currentEyes
        </svg>''';

      case ParotState.pointingUp:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Wing pointing up -->
          <path d="M140 110 L140 40" stroke="$navy" stroke-width="8" stroke-linecap="round" />
          <path d="M140 40 L130 55 M140 40 L150 55" stroke="$navy" stroke-width="4" stroke-linecap="round" />
          $currentEyes
        </svg>''';

      case ParotState.pointingDown:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Wing pointing down -->
          <path d="M140 110 L140 180" stroke="$navy" stroke-width="8" stroke-linecap="round" />
          <path d="M140 180 L130 165 M140 180 L150 165" stroke="$navy" stroke-width="4" stroke-linecap="round" />
          $currentEyes
        </svg>''';

      case ParotState.pointingLeft:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Wing pointing left -->
          <path d="M60 110 L-10 110" stroke="$navy" stroke-width="8" stroke-linecap="round" />
          <path d="M-10 110 L5 100 M-10 110 L5 120" stroke="$navy" stroke-width="4" stroke-linecap="round" />
          $currentEyes
        </svg>''';

      case ParotState.pointingRight:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 110 C100 110 140 130 140 100" fill="$white" stroke="$navy" stroke-linecap="round" stroke-width="6" />
          <path d="M80 70 L60 90 L80 110" fill="$navy" stroke="$navy" stroke-linejoin="round" stroke-width="6" />
          <!-- Wing pointing right -->
          <path d="M140 110 L210 110" stroke="$navy" stroke-width="8" stroke-linecap="round" />
          <path d="M210 110 L195 100 M210 110 L195 120" stroke="$navy" stroke-width="4" stroke-linecap="round" />
          $currentEyes
        </svg>''';

      case ParotState.anxious:
        return '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          $defs
          <circle cx="100" cy="110" fill="url(#bodyGradient)" r="70" stroke="$navy" stroke-width="6" />
          <path d="M100 125 Q110 120 120 125" fill="none" stroke="$navy" stroke-width="6" stroke-linecap="round" />
          <!-- Anxious Eyes -->
          <circle cx="85" cy="80" fill="$white" r="10" stroke="$navy" stroke-width="4" />
          <circle cx="88" cy="82" fill="$navy" r="3" />
          <circle cx="115" cy="80" fill="$white" r="10" stroke="$navy" stroke-width="4" />
          <circle cx="112" cy="82" fill="$navy" r="3" />
          <!-- Sweat Drop -->
          <path d="M145 70 Q150 80 145 90 Q140 80 145 70" fill="$blue" stroke="$navy" stroke-width="2" />
        </svg>''';
    }
  }
}
