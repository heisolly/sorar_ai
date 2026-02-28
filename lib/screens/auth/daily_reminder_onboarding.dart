import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parot_mascot.dart';
import '../../config/navigation_key.dart';

class DailyReminderOnboarding extends StatefulWidget {
  final VoidCallback onComplete;

  const DailyReminderOnboarding({super.key, required this.onComplete});

  @override
  State<DailyReminderOnboarding> createState() =>
      _DailyReminderOnboardingState();
}

class _DailyReminderOnboardingState extends State<DailyReminderOnboarding> {
  final NotificationService _notificationService = NotificationService();
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
  bool _isLoading = false;
  ParotState _mascotState = ParotState.idle;

  bool get _canAddMore => _selectedTimes.length < 3;

  Future<void> _enableReminder() async {
    setState(() => _isLoading = true);

    try {
      // 1. Request Permission
      final hasPermission = await _notificationService
          .requestNotificationPermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);

      if (!hasPermission) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Save settings
      await _notificationService.saveReminderSettings(
        enabled: true,
        times: _selectedTimes,
      );

      // 3. Schedule reminders (Non-blocking or with timeout to prevent hang)
      // If this fails, we still want the user to proceed
      try {
        await _notificationService
            .scheduleDailyReminders(_selectedTimes)
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Warning: Scheduling failed but proceeding: $e');
      }

      if (mounted) {
        _showSuccessMessage();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          widget.onComplete();
        }
      }
    } catch (e) {
      debugPrint('Error enabling reminder: $e');
      if (mounted) {
        _showErrorMessage();
        // Fallback: even if it fails, allow them to complete after a delay
        await Future.delayed(const Duration(seconds: 1));
        widget.onComplete();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mascotState = ParotState.celebrating;
        });
      }
    }
  }

  Future<void> _skipReminder() async {
    await _notificationService.saveReminderSettings(
      enabled: false,
      times: _selectedTimes,
    );
    if (mounted) {
      widget.onComplete();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.primaryNavy, width: 2),
        ),
        title: Text(
          'Permission Required',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'To receive daily reminders, please enable notifications in your device settings.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Daily reminder set! 🎉',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage() {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Failed to set reminder. Please try again.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addTime() async {
    if (!_canAddMore) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
        _mascotState = ParotState.happy;
      });
    }
  }

  void _removeTime(int index) {
    if (_selectedTimes.length <= 1) return;
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _editTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );

    if (picked != null && picked != _selectedTimes[index]) {
      setState(() {
        _selectedTimes[index] = picked;
        _mascotState = ParotState.happy;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPatternPainter())),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Top Logo
                Row(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),

                        // Mascot
                        ParotMascot(state: _mascotState, size: 220)
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Stay Consistent! 🎯',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          'Get a daily reminder to practice. Just 5 minutes a day can make a huge difference!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 40),

                        // Time Picker Area
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedTimes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildTimeCard(index);
                          },
                        ).animate().fadeIn(delay: 200.ms),

                        if (_canAddMore) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _addTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryNavy,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryNavy.withValues(
                                      alpha: 0.1,
                                    ),
                                    offset: const Offset(3, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppColors.primaryBrand,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add another reminder',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 250.ms),
                        ],

                        const SizedBox(height: 40),

                        // Benefits List
                        _buildBenefitItem(
                          icon: Icons.trending_up_rounded,
                          text: 'Build a consistent practice habit',
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                        const SizedBox(height: 16),

                        _buildBenefitItem(
                          icon: Icons.emoji_events_rounded,
                          text: 'Track your progress over time',
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                        const SizedBox(height: 16),

                        _buildBenefitItem(
                          icon: Icons.rocket_launch_rounded,
                          text: 'Accelerate your growth',
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _NeobrutalistButton(
                        text: 'Enable Daily Reminder',
                        onPressed: _enableReminder,
                        isLoading: _isLoading,
                        icon: Icons.notifications_active_rounded,
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _isLoading ? null : _skipReminder,
                        child: Text(
                          'Skip for now',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),
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

  Widget _buildTimeCard(int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNavy, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.1),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reminder #${index + 1}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _editTime(index),
                child: Row(
                  children: [
                    Text(
                      _formatTime(_selectedTimes[index]),
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primaryBrand,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedTimes.length > 1)
            IconButton(
              onPressed: () => _removeTime(index),
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryNavy, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryBrand),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeobrutalistButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const _NeobrutalistButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Stack(
        children: [
          // Shadow
          Transform.translate(
            offset: const Offset(4, 4),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryBrand,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Main Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          text,
                          style: AppTextStyles.buttonText.copyWith(
                            color: Colors.white,
                            fontSize: 16,
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
