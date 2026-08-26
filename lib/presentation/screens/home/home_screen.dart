import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/owner_profile_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../widgets/app_location_header.dart';
import '../../widgets/shimmer_list.dart';
import '../property/property_list_args.dart';
import '../property/property_name_search_args.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _fieldFill = Color(0xFFF2F3F5);
const _border = Color(0xFFECEDF0);

const _kCategories = ['All', 'House', 'Villa', 'Apartments', 'Other'];

bool _matchesCategory(Property p, String category) {
  if (category == 'All') return true;
  final haystack = '${p.categoryName ?? ''} ${p.propertyKind} ${p.name}'
      .toLowerCase();
  switch (category) {
    case 'House':
      return haystack.contains('house');
    case 'Villa':
      return haystack.contains('villa');
    case 'Apartments':
      return haystack.contains('apartment') || haystack.contains('flat');
    case 'Other':
      return !_matchesCategory(p, 'House') &&
          !_matchesCategory(p, 'Villa') &&
          !_matchesCategory(p, 'Apartments');
  }
  return true;
}

String _formatPrice(int price, String type) {
  final t = type.toLowerCase();
  if (t == 'rent' ||
      t == 'lease' ||
      t == 'pg' ||
      t == 'co-living' ||
      t == 'co-livin') {
    if (price >= 100000) {
      double lakhs = price / 100000.0;
      return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh/mo';
    }
    return '₹$price/mo';
  } else {
    if (price >= 10000000) {
      double crores = price / 10000000.0;
      return '₹${crores.toStringAsFixed(crores % 1 == 0 ? 0 : 2)} Cr';
    } else if (price >= 100000) {
      double lakhs = price / 100000.0;
      return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh';
    }
    return '₹$price';
  }
}

const _kFallbackImage =
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';

const _kSellBannerImage =
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=500&q=80&auto=format&fit=crop';

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final String _mode = 'rent';
  String _category = 'All';
  ProviderSubscription<LocationState>? _locationSub;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  @override
  void initState() {
    super.initState();
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.enabled) {
        final loc = ref.read(locationProvider);
        if (loc.currentLabel.isEmpty ||
            loc.currentLabel == 'Unknown Location' ||
            loc.currentLabel == 'Set location') {
          ref.read(locationProvider.notifier).fetchCurrent();
        }
      }
    });

    // Load saved location immediately
    Future<void>.microtask(() async {
      await ref.read(locationProvider.notifier).load();
      final ready = ref.read(locationProvider);
      if (ready.currentLabel.isNotEmpty &&
          ready.currentLabel != 'Unknown Location' &&
          ready.currentLabel != 'Set location') {
        if (!mounted) return;
        final token = ref.read(authProvider).user?.token;
        ref
            .read(propertyNotifierProvider.notifier)
            .loadHomeForMode(
              type: _mode,
              token: token,
              city: ready.currentLabel,
            );
      }
    });

    _locationSub = ref.listenManual(locationProvider, (prev, next) {
      final changed = prev?.currentLabel != next.currentLabel;
      if (changed &&
          next.currentLabel.isNotEmpty &&
          next.currentLabel != 'Unknown Location' &&
          next.currentLabel != 'Set location') {
        Future<void>.microtask(() {
          if (!mounted) return;
          final token = ref.read(authProvider).user?.token;
          ref
              .read(propertyNotifierProvider.notifier)
              .loadHomeForMode(
                type: _mode,
                token: token,
                city: next.currentLabel,
              );
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('has_prompted_location_v6') ?? false;

      if (!hasPrompted) {
        await prefs.setBool('has_prompted_location_v6', true);

        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.denied) {
            if (mounted) {
              AppSnackbar.showError(
                context,
                'Location helps us show nearby properties. You can still set it manually.',
              );
            }
          } else if (permission == LocationPermission.deniedForever) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Location Permission Needed'),
                  content: const Text(
                    'Please enable location permissions in app settings to automatically discover nearby properties.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Geolocator.openAppSettings();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
            }
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              if (mounted) {
                AppSnackbar.showError(
                  context,
                  'Please turn on your device GPS (Location) to find nearby properties.',
                );
              }
            } else {
              await ref.read(locationProvider.notifier).fetchCurrent();
            }
          }
        } catch (e) {
          debugPrint('Location Error: $e');
        }
      }

      if (!mounted) return;
      final token = ref.read(authProvider).user?.token;
      final loc = ref.read(locationProvider);

      if (loc.currentLabel.isEmpty ||
          loc.currentLabel == 'Unknown Location' ||
          loc.currentLabel == 'Set location') {
        ref
            .read(propertyNotifierProvider.notifier)
            .loadHomeForMode(type: _mode, token: token, city: loc.currentLabel);
      }
      if (token != null && token.trim().isNotEmpty) {
        ref
            .read(ownerProfileNotifierProvider.notifier)
            .load(token: token.trim());
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.close();
    _serviceStatusStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectivityProvider);
    final state = ref.watch(propertyNotifierProvider);

    ref.listen(propertyNotifierProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        AppSnackbar.showError(
          context,
          next.error!.replaceFirst('Exception: ', ''),
        );
      }
    });

    final featured = state.featured.toList(growable: false);

    final nearby = state.nearby.toList(growable: false);

    final recommended = (nearby.isNotEmpty ? nearby : state.recommended).toList(
      growable: false,
    );

    final recommendedFiltered = recommended
        .where((p) => _matchesCategory(p, _category))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: () {
          final token = ref.read(authProvider).user?.token;
          final loc = ref.read(locationProvider);
          return ref
              .read(propertyNotifierProvider.notifier)
              .loadHomeForMode(
                type: _mode,
                token: token,
                city: loc.currentLabel,
              );
        },
        child: CustomScrollView(
          slivers: [
            // ════════ HEADER ════════
            const SliverToBoxAdapter(child: AppLocationHeader()),

            // ════════ SEARCH BAR ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push('/location-search'),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: _grey,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Search something',
                            style: TextStyle(
                              color: _grey,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(
                            '/name-search-results',
                            extra: PropertyNameSearchArgs(
                              query: '',
                              mode: _mode,
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: _navy,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ════════ SELL YOUR PROPERTY ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push('/leads/new'),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7CC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 130,
                          child: CachedNetworkImage(
                            imageUrl: _kSellBannerImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFFFFD8A8)),
                            errorWidget: (context, url, error) =>
                                Container(color: const Color(0xFFFFD8A8)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 130, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Sell Your Property',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Get the best value for your property',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _orange,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'List Property',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ════════ FEATURED — horizontal scroll ════════
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Featured',
                onSeeAll: () => context.push(
                  '/properties',
                  extra: PropertyListArgs(
                    title: 'Featured Properties',
                    items: featured,
                  ),
                ),
              ),
            ),
            if (state.isLoading && state.all.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 236,
                  child: ShimmerList(itemCount: 3, itemHeight: 220),
                ),
              )
            else if (featured.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySection(label: 'No featured properties'),
              )
            else
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardW = MediaQuery.of(context).size.width * 0.86;
                    const contentH = 148.0;
                    final cardH = cardW * 11 / 16 + contentH;
                    return SizedBox(
                      height: cardH,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, i) {
                          final p = featured[i];
                          return _PropertyCard(
                                p: p,
                                width: cardW,
                                onTap: () => context.push('/property/${p.id}'),
                              )
                              .animate()
                              .fadeIn(delay: (60 * i).ms, duration: 260.ms)
                              .slideX(begin: 0.05);
                        },
                      ),
                    );
                  },
                ),
              ),

            // ════════ OUR RECOMMENDATION ════════
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Our Recommendation',
                onSeeAll: recommended.isEmpty
                    ? null
                    : () => context.push(
                        '/properties',
                        extra: PropertyListArgs(
                          title: 'Our Recommendation',
                          items: recommended,
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _kCategories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _kCategories[i];
                    final selected = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: selected ? _orange : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected ? _orange : _border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : _navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (state.isLoading && state.all.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: ShimmerList()),
              )
            else if (recommendedFiltered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _EmptySection(
                    label: recommended.isEmpty
                        ? (_mode == 'rent'
                              ? 'No rent properties found nearby'
                              : 'No properties for sale nearby')
                        : 'No properties in this category',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final p = recommendedFiltered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child:
                          _PropertyCard(
                                p: p,
                                onTap: () => context.push('/property/${p.id}'),
                              )
                              .animate()
                              .fadeIn(delay: (50 * i).ms, duration: 240.ms)
                              .slideY(begin: 0.04),
                    );
                  }, childCount: recommendedFiltered.length),
                ),
              ),

            // ════════ CONNECTIVITY ════════
            SliverToBoxAdapter(
              child: conn.when(
                data: (r) => r == ConnectivityResult.none
                    ? _ConnectivityBanner(
                        onRetry: () => ref.invalidate(connectivityProvider),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: _orange,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: _orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROPERTY CARD — image w/ dots + heart/share, then details panel.
//  Used both for the horizontal Featured scroller and the vertical
//  Our Recommendation list (pass `width` for the former, omit for the
//  latter to fill the available width).
// ─────────────────────────────────────────────────────────────
String _formatArea(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class _PropertyCard extends ConsumerWidget {
  final Property p;
  final VoidCallback onTap;
  final double? width;

  const _PropertyCard({required this.p, required this.onTap, this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthed = ref.watch(authProvider).user != null;
    final isFav = ref.watch(favoritesProvider.select((s) => s.contains(p.id)));

    void toggleFavorite() {
      if (!isAuthed) {
        AppSnackbar.showError(context, 'Please login to add favorites');
        context.push('/login?from=${Uri.encodeComponent('/property/${p.id}')}');
        return;
      }
      ref
          .read(favoritesProvider.notifier)
          .toggleRemote(type: 'property', id: p.id)
          .catchError((_) {
            if (!context.mounted) return;
            AppSnackbar.showError(
              context,
              'Failed to update wishlist. Please try again.',
            );
          });
    }

    void share() {
      final shareText =
          '🏡 *Check out this property!*\n\n'
          '*${p.name}*\n'
          '📍 Location: ${p.location}\n'
          '💰 Price: ${_formatPrice(p.price, p.type)}\n';
      Share.share(shareText, subject: p.name);
    }

    final isRent =
        p.type.toLowerCase() == 'rent' || p.type.toLowerCase() == 'lease';
    final deposit = p.securityDeposit;
    final areaValue = p.builtUpArea ?? p.area;
    final areaLabel = p.builtUpArea != null ? 'Built-up Area' : 'Area';
    final dotCount = p.images.length.clamp(0, 5);

    final highlights = <String>[
      if ((p.facing ?? '').trim().isNotEmpty) '${p.facing!.trim()} Facing',
      if ((p.furnishing ?? '').trim().isNotEmpty) p.furnishing!.trim(),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: p.images.isEmpty
                          ? _kFallbackImage
                          : p.images.first.trim(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: _fieldFill),
                      errorWidget: (context, url, error) =>
                          Container(color: _fieldFill),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: toggleFavorite,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav ? const Color(0xFFE0245E) : _navy,
                                size: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: share,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                color: _navy,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dotCount > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(dotCount, (i) {
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2.5,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: i == 0 ? 0.95 : 0.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: p.name,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (p.location.trim().isNotEmpty)
                          TextSpan(
                            text: '  in ${p.location}',
                            style: const TextStyle(
                              color: _grey,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatPrice(p.price, p.type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (isRent && deposit != null && deposit > 0)
                              Text(
                                '+ Deposit ₹$deposit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (areaValue != null) ...[
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_formatArea(areaValue)} ${p.areaUnit ?? 'sqft'}',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              areaLabel,
                              style: const TextStyle(
                                color: _grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 22,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Center(
                              child: Text(
                                'Highlights:',
                                style: TextStyle(
                                  color: _grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          for (final h in highlights)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: _fieldFill,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  h,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONNECTIVITY BANNER
// ─────────────────────────────────────────────────────────────
class _ConnectivityBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConnectivityBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD97A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF856404),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No internet connection',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF856404),
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF856404),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
