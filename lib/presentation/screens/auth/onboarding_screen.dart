import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/white_pill_button.dart';

class _Tile {
  final String asset;
  final double x, y, w, h;
  const _Tile(this.asset, this.x, this.y, this.w, this.h);
}

const _kGridTiles = <_Tile>[
  _Tile('assets/icons/onboarding_tiles/tile_0.jpeg', 16, 0, 109, 130),
  _Tile('assets/icons/onboarding_tiles/tile_1.jpeg', 16, 139, 109, 140),
  _Tile('assets/icons/onboarding_tiles/tile_2.jpeg', 16, 288, 109, 175),
  _Tile('assets/icons/onboarding_tiles/tile_1.jpeg', 16, 472, 109, 78),
  _Tile('assets/icons/onboarding_tiles/tile_3.jpeg', 145, 0, 109, 175),
  _Tile('assets/icons/onboarding_tiles/tile_4.jpeg', 145, 184, 109, 130),
  _Tile('assets/icons/onboarding_tiles/tile_5.jpeg', 145, 323, 109, 140),
  _Tile('assets/icons/onboarding_tiles/tile_1.jpeg', 145, 472, 109, 78),
  _Tile('assets/icons/onboarding_tiles/tile_6.jpeg', 274, 0, 109, 132),
  _Tile('assets/icons/onboarding_tiles/tile_7.jpeg', 274, 141, 109, 140),
  _Tile('assets/icons/onboarding_tiles/tile_8.jpeg', 274, 290, 109, 175),
  _Tile('assets/icons/onboarding_tiles/tile_1.jpeg', 274, 474, 109, 78),
];
const double _kGridViewportW = 399;
const double _kGridViewportH = 552;

class _OnboardingPhotoGrid extends StatelessWidget {
  const _OnboardingPhotoGrid();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _kGridViewportW / _kGridViewportH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / _kGridViewportW;
          return ClipRect(
            child: Stack(
              children: [
                for (final t in _kGridTiles)
                  Positioned(
                    left: t.x * scale,
                    top: t.y * scale,
                    width: t.w * scale,
                    height: t.h * scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10 * scale),
                      child: Image.asset(t.asset, fit: BoxFit.cover),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.565, 0.928, 1.0],
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0),
                            Colors.white,
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _navy = Color(0xFF191D31);
  static const _grey = Color(0xFF666876);
  static const _orange = Color(0xFFFF8000);

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).setSeenOnboarding();
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    const _OnboardingPhotoGrid(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Text(
                        'WELCOME TO NESTORA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          children: const [
                            TextSpan(text: "Let's Get You Closer To "),
                            TextSpan(
                              text: 'Your Ideal Home',
                              style: TextStyle(color: _orange),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
                      const SizedBox(height: 14),
                      const Text(
                        'Login to NESTORA with Phone Number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 160.ms),
                      const SizedBox(height: 28),
                      WhitePillButton(
                        label: 'Login',
                        onTap: () => _continue(context, ref),
                      ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
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
}
