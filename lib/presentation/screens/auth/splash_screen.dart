import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../presentation/widgets/error_retry.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/location_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _booting = true;
  String? _error;
  String _step = 'Starting…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authNotifier = ref.read(authProvider.notifier);
      final favoritesNotifier = ref.read(favoritesProvider.notifier);
      final locationNotifier = ref.read(locationProvider.notifier);
      _bootstrap(authNotifier, favoritesNotifier, locationNotifier);
    });
  }

  Future<void> _bootstrap(
    AuthNotifier authNotifier,
    FavoritesNotifier favoritesNotifier,
    LocationNotifier locationNotifier,
  ) async {
    setState(() {
      _booting = true;
      _error = null;
      _step = 'Preparing…';
    });
    try {
      setState(() => _step = 'Loading session…');
      await authNotifier.bootstrap().timeout(const Duration(seconds: 8));
      setState(() => _step = 'Loading saved data…');
      await Future.wait([
        favoritesNotifier.load(),
        locationNotifier.load(),
      ]).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      // Router redirect will route to onboarding/login/home based on `auth`.
      // Navigation is handled by GoRouter redirect from `/splash`.
      setState(() => _step = 'Opening…');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _step = 'Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.20),
              cs.tertiary.withValues(alpha: 0.18),
              cs.surface,
            ],
          ),
        ),
        child: Center(
          child: _error != null
              ? ErrorRetry(
                  title: 'Startup failed',
                  message: _error!,
                  onRetry: () {
                    final authNotifier = ref.read(authProvider.notifier);
                    final favoritesNotifier = ref.read(
                      favoritesProvider.notifier,
                    );
                    final locationNotifier = ref.read(
                      locationProvider.notifier,
                    );
                    _bootstrap(
                      authNotifier,
                      favoritesNotifier,
                      locationNotifier,
                    );
                  },
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.tertiary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.22),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 18),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 6),
                    Text(
                      _step,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ).animate().fadeIn(delay: 160.ms),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 180,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _booting ? 1 : 0,
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(999),
                          color: cs.primary,
                          backgroundColor: cs.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ).animate().fadeIn(delay: 240.ms),
                  ],
                ),
        ),
      ),
    );
  }
}
