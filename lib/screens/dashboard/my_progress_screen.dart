import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/noise_background.dart';
import '../auth/auth_screen.dart';

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
  String _userHandle = '@user';

  // Stats
  double _avgConfidence = 0.0;
  int _totalGames = 0;
  // int _totalAttempts = 0; // Unused for now in new design

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
      final name = await _profileService.getUserName();
      final user = _supabase.currentUser;
      final email = user?.email;
      final handle = email?.split('@').first ?? 'user';

      if (mounted) {
        setState(() {
          _userName = name;
          _userHandle = '@$handle';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      final allSessions = await _supabase.getChatSessions(limit: 50);
      // Filter for Rizz/Roast sessions
      final rizzSessions = allSessions.where((s) {
        final meta = s['metadata'] ?? {};
        final type = meta['scenario_type'] as String?;
        return type == 'Roast Me' || (type?.contains('Rizz') ?? false);
      }).toList();

      if (mounted) {
        setState(() {
          _sessions = rizzSessions;
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
      // _totalAttempts = 0;
      return;
    }

    _totalGames = _sessions.length;
    double totalConf = 0;
    int scoredGames = 0;
    // int reps = 0;

    for (var s in _sessions) {
      final meta = s['metadata'] ?? {};
      final scores = meta['last_score'];

      // Calculate attempts
      // final attempts = meta['attempts_count'];
      // if (attempts is int) reps += attempts;

      // Calculate confidence
      if (scores != null && scores is Map) {
        final conf = scores['confidence'];
        if (conf is num) {
          totalConf += conf;
          scoredGames++;
        }
      }
    }

    _avgConfidence = scoredGames > 0 ? totalConf / scoredGames : 0.0;
    // _totalAttempts = reps;
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
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
      body: NoiseBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryCTA),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // --- Profile Header ---
                      Stack(
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
                              // Placeholder avatar if no URL
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.border,
                              ),
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
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userHandle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUserEmail,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Stats Card (Green/Dark Card Style) ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors
                              .primaryCTA, // Dark brown to match "Green" contrast
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
                                  style: GoogleFonts.inter(
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _totalGames.toString(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "GMs", // Games
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.heroCardTextSecondary,
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
                                    color:
                                        AppColors.scenarioFamily, // Amber/Gold
                                    size: 24,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Menu Items ---
                      Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            label: 'View Profile',
                            onTap: () {
                              // View full profile details if needed
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            icon: Icons.history,
                            label: 'My Simulations',
                            onTap: () {
                              // Navigate to detailed history if implemented
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            icon: Icons.star_outline,
                            label: 'My Ratings',
                            onTap: () {
                              // Detailed ratings
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            icon: Icons.people_outline,
                            label: 'Community',
                            onTap: () {
                              // Community feature
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            onTap: () {
                              // Navigate to settings
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            label: 'Help & Feedback',
                            onTap: () {
                              // Help
                            },
                          ),
                          const SizedBox(height: 32),
                          _buildMenuItem(
                            icon: Icons.logout,
                            label: 'Log out',
                            isDestructive: true,
                            onTap: _handleLogout,
                          ),
                        ],
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
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.warning : AppColors.textPrimary;
    final iconColor = isDestructive
        ? AppColors.warning
        : AppColors.secondaryAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCTA.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
