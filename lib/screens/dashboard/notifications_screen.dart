import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              // Mark all as read
            },
          ),
        ],
      ),
      body: NoiseBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildDateHeader("Today"),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.scenarioRizz,
              title: "Level Up!",
              description: "You've reached Rizz Level 5. Keep it up!",
              time: "2m ago",
              isUnread: true,
            ),
            _buildNotificationItem(
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.secondaryAccent,
              title: "New Scenario Available",
              description: "Try out the new 'Salary Negotiation' scenario.",
              time: "1h ago",
              isUnread: true,
            ),
            const SizedBox(height: 24),
            _buildDateHeader("Yesterday"),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.tips_and_updates_outlined,
              iconColor: AppColors.scenarioFamily,
              title: "Daily Tip",
              description:
                  "Maintain eye contact for 50-70% of the conversation.",
              time: "1d ago",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    bool isUnread = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppColors.energyAccent.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AppColors.energyAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.energyAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
