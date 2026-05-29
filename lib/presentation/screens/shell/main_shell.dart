import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../../widgets/keep_alive_page.dart';
import '../home/home_screen.dart';
import '../home/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../property/properties_tab_screen.dart';

// ─────────────────────────────────────────────────────────────
//  NAV ITEMS
// ─────────────────────────────────────────────────────────────
const _navItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavItem(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment_rounded,
    label: 'Properties',
  ),
  NavItem(
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    label: 'Saved',
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

// ─────────────────────────────────────────────────────────────
//  MAIN SHELL
// ─────────────────────────────────────────────────────────────
/// The root shell that hosts all 4 main tabs inside a [PageView].
/// Swipe gestures and bottom-nav taps are kept in sync via
/// [navProvider] (Riverpod) + [PageController].
///
/// Each page is wrapped in [KeepAlivePage] so Flutter never destroys
/// a tab's widget tree when the user navigates away — identical to
/// Instagram's behaviour.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;
  int? _pendingIndex;

  // Auth-gated tab indices (0-based)
  static const _authGated = {2, 3}; // Saved, Profile

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(navProvider),
      // keepPage: true ensures the controller remembers the page even if
      // the widget is temporarily removed from the tree.
      keepPage: true,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Called by bottom nav tap ──────────────────────────────
  void _onNavTap(int index) {
    if (index == ref.read(navProvider)) return;
    final isAuthed = ref.read(authProvider).user != null;

    if (_authGated.contains(index) && !isAuthed) {
      final labels = ['', '', 'saved', 'profile'];
      AppSnackbar.showError(context, 'Please login to view ${labels[index]}');
      _pendingIndex = index;
      context.push('/login?from=${Uri.encodeComponent('/home')}');
      return;
    }

    _pendingIndex = null;
    ref.read(navProvider.notifier).goTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── Called by PageView swipe ──────────────────────────────
  void _onPageChanged(int index) {
    if (index == ref.read(navProvider)) {
      // Settle back to original page after snap-back or redundant trigger
      return;
    }

    final isAuthed = ref.read(authProvider).user != null;

    if (_authGated.contains(index) && !isAuthed) {
      // Snap back to previous page — don't allow swipe into auth-gated tab
      final current = ref.read(navProvider);
      _pageController.animateToPage(
        current,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      final labels = ['', '', 'saved', 'profile'];
      AppSnackbar.showError(context, 'Please login to view ${labels[index]}');
      _pendingIndex = index;
      context.push('/login?from=${Uri.encodeComponent('/home')}');
      return;
    }

    _pendingIndex = null;
    ref.read(navProvider.notifier).goTo(index);
    // Haptic on swipe too
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navProvider);

    // Sync the PageController whenever navProvider changes from *any* caller,
    // not just _onNavTap. This makes external goTo(0) calls work correctly.
    ref.listen<int>(navProvider, (prev, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    ref.listen(authProvider, (prev, next) {
      if (next.user != null && _pendingIndex != null) {
        final target = _pendingIndex!;
        _pendingIndex = null;
        ref.read(navProvider.notifier).goTo(target);
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            target,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });

    return Scaffold(
      // No AppBar here — each tab manages its own
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // Allow natural swipe physics — same as Instagram
        physics: const BouncingScrollPhysics(),
        children: const [
          KeepAlivePage(child: HomeScreen()),
          KeepAlivePage(child: PropertiesTabScreen()),
          KeepAlivePage(child: FavoritesScreen()),
          KeepAlivePage(child: ProfileScreen()),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}
