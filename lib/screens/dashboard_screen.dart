import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'home_screen.dart';
import 'ai_chat_screen.dart';
import 'cards/scenario_cards_screen.dart';
import 'dashboard/progress_dashboard_screen.dart';
import 'simulation_setup_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_background.dart';
import '../widgets/dashboard_tour_overlay.dart';
import '../services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===========================================================================
// Keep-Alive Wrapper — keeps every page alive in the PageView
// so switching tabs never triggers a reload
// ===========================================================================
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ===========================================================================
// DashboardScreen
// ===========================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _SorarDashboardScreenState();
}

class _SorarDashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _showTour = false;
  late final PageController _pageController;
  late final List<Widget> _screens;

  // Maps logical tab order → visual nav position
  // Nav order: Home(0), Learn(3), Coach(2), Chat(1), Profile(4)
  static const List<int> _navOrder = [0, 3, 2, 1, 4];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 1.0,
    );

    _runSafeTourCheck();

    _screens = [
      _KeepAliveWrapper(child: const HomeScreen()),
      _KeepAliveWrapper(child: AIChatScreen(onBack: () => _onItemTapped(0))),
      _KeepAliveWrapper(child: const SimulationSetupScreen()),
      _KeepAliveWrapper(child: const ScenarioCardsScreen()),
      _KeepAliveWrapper(child: const ProgressDashboardScreen()),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Ghost-call guard
  @override
  dynamic noSuchMethod(Invocation invocation) {
    debugPrint('!!! GHOST CALL ON DASHBOARD: ${invocation.memberName} !!!');
    return super.noSuchMethod(invocation);
  }

  Future<void> _runSafeTourCheck() async {
    try {
      await _checkTourStatusSafely();
    } catch (e, stack) {
      debugPrint("DEBUG: _runSafeTourCheck caught: $e\n$stack");
    }
  }

  Future<void> _checkTourStatusSafely() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('hasSeenDashboardTour') ?? false;
    if (hasSeenTour) return;

    try {
      final dynamic rawData = await UserProfileService().getUserProfile();
      if (rawData != null && rawData is Map) {
        final createdAtVal = rawData['created_at'];
        if (createdAtVal != null && createdAtVal is String) {
          final createdAt = DateTime.parse(createdAtVal);
          if (DateTime.now().difference(createdAt).inMinutes > 15) {
            await prefs.setBool('hasSeenDashboardTour', true);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking tour eligibility safely: $e");
    }

    if (mounted) setState(() => _showTour = true);
  }

  Future<void> _completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenDashboardTour', true);
    if (mounted) setState(() => _showTour = false);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _shouldHideNav() => _selectedIndex == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PremiumBackground(
        child: Stack(
          children: [
            // ── Main paged content with swipe support ──────────────────────
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: _screens,
            ),

            // ── Bottom nav bar ──────────────────────────────────────────────
            if (MediaQuery.of(context).viewInsets.bottom == 0 &&
                !_shouldHideNav())
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildModernDockNav(),
              ),

            // ── Onboarding tour ─────────────────────────────────────────────
            if (_showTour)
              Positioned.fill(
                child: DashboardTourOverlay(
                  onComplete: _completeTour,
                  onSkip: _completeTour,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Navigation bar ────────────────────────────────────────────────────────

  Widget _buildModernDockNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              _buildSlidingIndicator(),
              Row(
                children: [
                  _dockItem(HugeIcons.strokeRoundedHome01, 0),
                  _dockItem(HugeIcons.strokeRoundedBookOpen01, 3),
                  _dockItem(HugeIcons.strokeRoundedMic01, 2),
                  _dockItem(HugeIcons.strokeRoundedChatting01, 1),
                  _dockItem(HugeIcons.strokeRoundedUserCircle, 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;
    final visualIndex = _navOrder.indexOf(_selectedIndex).clamp(0, 4);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: (visualIndex * itemWidth) + (itemWidth - 28) / 2,
      top: 0,
      child: Container(
        width: 28,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.primaryBrand,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _dockItem(List<List<dynamic>> icon, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: HugeIcon(
              icon: icon,
              color: isSelected
                  ? AppColors.primaryBrand
                  : Colors.black.withValues(alpha: 0.28),
              size: 26,
              strokeWidth: isSelected ? 2.0 : 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
