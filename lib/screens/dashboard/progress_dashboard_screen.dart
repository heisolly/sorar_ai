import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_background.dart';
import '../../widgets/motion/smooth_fade_in.dart';
import '../../widgets/motion/pressable_scale.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'my_simulations_screen.dart';
import 'faq_screen.dart';
import '../onboarding/parot_onboarding_screen.dart';
import 'about_app_screen.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final SupabaseService _supabase = SupabaseService();
  final UserProfileService _profileService = UserProfileService();

  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;
  String _userName = 'User';
  String? _avatarUrl;

  // Stats
  double _avgConfidence = 0.0;
  int _totalGames = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtime();
    _loadProfile();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      _supabase.unsubscribe(_subscription!);
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getUserProfile();
      final user = _supabase.currentUser;

      String name = 'User';
      if (profile != null && profile['name'] != null) {
        name = profile['name'].toString().split(' ').first;
      } else if (user?.userMetadata?['full_name'] != null) {
        name = user!.userMetadata!['full_name'].toString().split(' ').first;
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _avatarUrl = profile?['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      final allSessions = await _supabase.getChatSessions(limit: 50);
      // Filter for Rizz/Roast sessions or just count all for "Games Played"
      // User requested "Rizz Level", so probably focus on relevant ones, but "Games Started" usually implies all.
      // Reverting to previous logic of filtering for Rizz/Roast to keep "Rizz" stats accurate.
      final rizzSessions = allSessions.where((s) {
        final meta = s['metadata'] ?? {};
        final type = meta['scenario_type'] as String?;
        return type == 'Roast Me' || (type?.contains('Rizz') ?? false);
      }).toList();

      if (mounted) {
        setState(() {
          _sessions =
              rizzSessions; // Or use allSessions for total games count? kept as rizzSessions for consistency.
          _calculateStats();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching progress: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    final user = _supabase.currentUser;
    if (user == null) return;

    _subscription = _supabase.subscribeToChatSessions(
      onUpdate: (payload) {
        if (!mounted) return;
        _fetchData();
      },
    );
  }

  void _calculateStats() {
    if (_sessions.isEmpty) {
      _avgConfidence = 0.0;
      _totalGames = 0;
      return;
    }

    _totalGames = _sessions.length;
    double totalConf = 0;
    int scoredGames = 0;

    for (var s in _sessions) {
      final meta = s['metadata'] ?? {};
      final scores = meta['last_score'];

      if (scores != null && scores is Map) {
        final conf = scores['confidence'];
        if (conf is num) {
          totalConf += conf;
          scoredGames++;
        }
      }
    }

    _avgConfidence = scoredGames > 0 ? totalConf / scoredGames : 0.0;
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ParotOnboardingScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _supabase.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryCTA),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // --- Profile Avatar & Info ---
                      SmoothFadeIn(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // Allow quick navigate to edit profile
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadProfile();
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryCTA,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColors.surface,
                                      backgroundImage: _avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                          : null,
                                      child: _avatarUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.border,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryCTA,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryBackground,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUserEmail,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Stats Card ---
                      SmoothFadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.energyAccent, // Vibrant Indigo
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCTA.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                    "Rizz Level",
                                    style: GoogleFonts.manrope(
                                      color: AppColors.heroCardTextSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _totalGames.toString(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "GMs", // Games
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              AppColors.heroCardTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Stars
                              Row(
                                children: List.generate(5, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      index < _avgConfidence.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: AppColors.scenarioFamily,
                                      size: 24,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // --- Menu Items ---
                      SmoothFadeIn(
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              label: 'My Profile',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadProfile();
                                }
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.history,
                              label: 'My Simulations',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MySimulationsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              label: 'FAQ',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FAQScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              label: 'About App',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AboutAppScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildMenuItem(
                              icon: Icons.logout,
                              label: 'Log out',
                              isLogout: true,
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: PressableScale(
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent, // Ensure hit test works
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLogout
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isLogout ? AppColors.warning : AppColors.textPrimary,
              ),
            ),
            title: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLogout ? AppColors.warning : AppColors.textPrimary,
              ),
            ),
            trailing: isLogout
                ? null
                : Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
