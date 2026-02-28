import 'package:flutter/material.dart';
import 'package:parot_ai/theme/app_theme.dart';

class SpeechWaveform extends StatefulWidget {
  final bool isListening;
  final double power; // 0.0 to 1.0

  const SpeechWaveform({
    super.key,
    required this.isListening,
    this.power = 0.0,
  });

  @override
  State<SpeechWaveform> createState() => _SpeechWaveformState();
}

class _SpeechWaveformState extends State<SpeechWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(20, (index) {
            // Calculate a wave-like height
            double wave = 0.0;
            if (widget.isListening) {
              // Pulse based on power and index
              wave =
                  widget.power * (0.5 + 0.5 * (1.0 - (index - 10).abs() / 10));
              // Add some randomness/flutter
              wave +=
                  0.2 *
                  (MediaQuery.of(context).size.width %
                      (index + 1) /
                      (index + 1));
            } else {
              // Gentle idle breathing
              wave =
                  0.1 +
                  0.1 * _idleController.value * (1.0 - (index - 10).abs() / 10);
            }

            double height = 10 + (wave * 80);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: widget.isListening
                    ? AppColors.primaryBrand
                    : AppColors.primaryNavy.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
