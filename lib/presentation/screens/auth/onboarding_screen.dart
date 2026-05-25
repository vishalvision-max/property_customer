import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../presentation/widgets/glass_container.dart';
import '../../../presentation/widgets/primary_button.dart';
import '../../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = const <_OnboardPageData>[
      _OnboardPageData(
        title: 'Discover premium homes',
        message:
            'Search curated properties with beautiful photos, amenities, and availability.',
        icon: Icons.search_rounded,
      ),
      _OnboardPageData(
        title: 'Save your favorites',
        message:
            'Tap the heart to shortlist. Your favorites stay synced and ready for backend.',
        icon: Icons.favorite_rounded,
      ),
      _OnboardPageData(
        title: 'Schedule visits instantly',
        message:
            'Pick future dates and time slots, then contact agents with one tap.',
        icon: Icons.calendar_month_rounded,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [
                    cs.primary.withValues(alpha: 0.18),
                    cs.tertiary.withValues(alpha: 0.10),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(authProvider.notifier)
                              .setSeenOnboarding();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final p = pages[i];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                          height: 130,
                                          width: 130,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [cs.primary, cs.tertiary],
                                            ),
                                          ),
                                          child: Icon(
                                            p.icon,
                                            size: 62,
                                            color: Colors.white,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(duration: 350.ms)
                                        .scale(begin: const Offset(0.9, 0.9)),
                                    const SizedBox(height: 22),
                                    Text(
                                          p.title,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 100.ms)
                                        .slideY(begin: 0.08),
                                    const SizedBox(height: 10),
                                    Text(
                                      p.message,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ).animate().fadeIn(delay: 140.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: i == _index ? 24 : 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i == _index
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _index == pages.length - 1
                        ? 'Get started'
                        : 'Continue',
                    onPressed: () async {
                      if (_index < pages.length - 1) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        await ref
                            .read(authProvider.notifier)
                            .setSeenOnboarding();
                        if (!context.mounted) return;
                        context.go('/login');
                      }
                    },
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

class _OnboardPageData {
  final String title;
  final String message;
  final IconData icon;
  const _OnboardPageData({
    required this.title,
    required this.message,
    required this.icon,
  });
}
