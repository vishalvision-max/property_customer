import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/owner_profile_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/lead_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../property/property_list_args.dart';
import '../search/search_args.dart';
import '../search/name_search_args.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _mode = 'rent';
  ProviderSubscription<LocationState>? _locationSub;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _visibleCount = 3;

  @override
  void initState() {
    super.initState();
    // Load saved location label; try to fetch GPS location automatically
    // so nearby/recommendations can work without manual tap.
    Future<void>.microtask(() async {
      await ref.read(locationProvider.notifier).load();
      final loc = ref.read(locationProvider);
      if (loc.lat == null || loc.lng == null) {
        await ref.read(locationProvider.notifier).fetchCurrent();
      }
      // Once coordinates are ready, reload home data with location so
      // nearby properties are used as the data source.
      final ready = ref.read(locationProvider);
      if (ready.lat != null && ready.lng != null) {
        if (!mounted) return;
        final token = ref.read(authProvider).user?.token;
        ref
            .read(propertyNotifierProvider.notifier)
            .loadHomeForMode(
              type: _mode,
              token: token,
              lat: ready.lat,
              lng: ready.lng,
            );
      }
    });

    _locationSub = ref.listenManual(locationProvider, (prev, next) {
      final changed = (prev?.lat != next.lat) || (prev?.lng != next.lng);
      if (changed && next.lat != null && next.lng != null) {
        Future<void>.microtask(() {
          if (!mounted) return;
          final token = ref.read(authProvider).user?.token;
          ref
              .read(propertyNotifierProvider.notifier)
              .loadHomeForMode(
                type: _mode,
                token: token,
                lat: next.lat,
                lng: next.lng,
              );
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = ref.read(authProvider).user?.token;
      final loc = ref.read(locationProvider);
      // Load with the default mode ('rent') so the initial view is already filtered.
      ref
          .read(propertyNotifierProvider.notifier)
          .loadHomeForMode(
            type: _mode,
            token: token,
            lat: loc.lat,
            lng: loc.lng,
          );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectivityProvider);
    final location = ref.watch(locationProvider);
    final state = ref.watch(propertyNotifierProvider);
    final isAuthed = ref.watch(authProvider).user != null;

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

    final recommendedTitle = nearby.isNotEmpty
        ? 'Nearby Properties'
        : 'Recommended';

    final defaultBudget = _mode == 'rent'
        ? const RangeValues(500, 5000)
        : const RangeValues(0, 3000000);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: _HomeDrawer(currentMode: _mode),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: () {
          final token = ref.read(authProvider).user?.token;
          final loc = ref.read(locationProvider);
          setState(() {
            _visibleCount = 3;
          });
          return ref
              .read(propertyNotifierProvider.notifier)
              .loadHomeForMode(
                type: _mode,
                token: token,
                lat: loc.lat,
                lng: loc.lng,
              );
        },
        child: CustomScrollView(
          slivers: [
            // ════════ HEADER ════════
            SliverToBoxAdapter(
              child: _HomeHeader(
                locationLabel: location.currentLabel,
                onTapLocation: () => _openLocationSheet(context),
                onTapMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onTapNotifications: () => context.push('/notifications'),
                onTapSearch: () => context.push(
                  '/name-search',
                  extra: NameSearchArgs(mode: _mode),
                ),
                onTapFilters: () => context.push('/search'),
              ),
            ),

            // ════════ QUICK ACTIONS ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _QuickActions(
                  onItemTap: (label) {
                    switch (label) {
                      case 'Buy':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'buy',
                            budget: const RangeValues(0, 3000000),
                            propertyType: 'Any',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'Rent':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'rent',
                            budget: const RangeValues(500, 5000),
                            propertyType: 'Any',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'PG / Living':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'rent',
                            budget: const RangeValues(500, 5000),
                            propertyType: 'PG',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'Commercial':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'buy',
                            budget: const RangeValues(0, 3000000),
                            propertyType: 'Commercial',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'Land/Plot':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'buy',
                            budget: const RangeValues(0, 3000000),
                            propertyType: 'Plot',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'New Projects':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'buy',
                            budget: const RangeValues(0, 3000000),
                            propertyType: 'New Project',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      case 'Builders':
                        context.push(
                          '/properties',
                          extra: SearchArgs(
                            mode: 'buy',
                            budget: const RangeValues(0, 3000000),
                            propertyType: 'Any',
                            amenities: const [],
                            locationQuery: '',
                            fromTab: true,
                          ),
                        );
                      default: // More — show all properties
                        context.push('/properties');
                    }
                  },
                ),
              ),
            ),

            // ════════ POPULAR SEARCHES ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PopularSearches(
                  items: const [
                    '2 BHK ',
                    'Flats under 50L',
                    'Near Railway Station',
                    'Ready to Move',
                    'Furnished',
                    'Gated Society',
                  ],
                  onTapItem: (label) {
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: _mode,
                        budget: defaultBudget,
                        propertyType: 'Any',
                        amenities: const [],
                        locationQuery: label,
                      ),
                    );
                  },
                ),
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

            // ════════ CREATE LEAD CTA ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _CreateLeadBanner(
                  onTap: () => context.push('/leads/new'),
                ),
              ),
            ),

            // ════════ FEATURED — horizontal scroll ════════
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Featured Properties',
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
                  height: 200,
                  child: ShimmerList(itemCount: 3, itemHeight: 170),
                ),
              )
            else if (featured.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySection(label: 'No featured properties'),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 236,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final p = featured[i];
                      return _FeaturedPropertyCard(
                            p: p,
                            onTap: () => context.push('/property/${p.id}'),
                          )
                          .animate()
                          .fadeIn(delay: (60 * i).ms, duration: 260.ms)
                          .slideX(begin: 0.05);
                    },
                  ),
                ),
              ),

            // ════════ TOP BUILDERS ════════
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Top Builders',
                onSeeAll: () => context.push('/properties'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _BuilderChip(asset: 'assets/icons/Dlf_pbu.png'),
                    SizedBox(width: 10),
                    _BuilderChip(asset: 'assets/icons/godrej.png'),
                    SizedBox(width: 10),
                    _BuilderChip(asset: 'assets/icons/ats.png'),
                    SizedBox(width: 10),
                    _BuilderChip(asset: 'assets/icons/emaar.png'),
                    SizedBox(width: 10),
                    _BuilderChip(asset: 'assets/icons/prestige.png'),
                  ],
                ),
              ),
            ),

            // ════════ RECOMMENDED / NEARBY — vertical list ════════
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: recommendedTitle,
                trailing: IconButton(
                  onPressed: () {
                    if (!isAuthed) {
                      AppSnackbar.showError(
                        context,
                        'Please login to view saved',
                      );
                      context.push(
                        '/login?from=${Uri.encodeComponent('/favorites')}',
                      );
                      return;
                    }
                    context.push('/favorites');
                  },
                  icon: const Icon(Icons.favorite_border_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: _kPrimary.withValues(alpha: 0.08),
                    foregroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            if (state.isLoading && state.all.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: ShimmerList()),
              )
            else if (recommended.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _EmptySection(
                    label: _mode == 'rent'
                        ? 'No rent properties found nearby'
                        : 'No properties for sale nearby',
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverList.separated(
                  itemCount: recommended.take(_visibleCount).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final p = recommended[i];
                    return PropertyCard(
                          property: p,
                          onTap: () => context.push('/property/${p.id}'),
                        )
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 240.ms)
                        .slideY(begin: 0.04);
                  },
                ),
              ),
              if (recommended.length > _visibleCount)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _visibleCount += 3;
                            });
                          },
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Load More Properties',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 2,
                            shadowColor: _kPrimary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Showing ${_visibleCount > recommended.length ? recommended.length : _visibleCount} of ${recommended.length} properties',
                          style: const TextStyle(
                            color: _kTextMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LocationSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER  — full-bleed image + gradient overlay
// ─────────────────────────────────────────────────────────────
const String _kHomeHeroImageUrl =
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=900&q=85';

class _HomeHeader extends StatelessWidget {
  final String locationLabel;
  final VoidCallback onTapMenu;
  final VoidCallback onTapLocation;
  final VoidCallback onTapNotifications;
  final VoidCallback onTapSearch;
  final VoidCallback onTapFilters;

  const _HomeHeader({
    required this.locationLabel,
    required this.onTapMenu,
    required this.onTapLocation,
    required this.onTapNotifications,
    required this.onTapSearch,
    required this.onTapFilters,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final totalH = topPad + 280.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: totalH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Property photo — image is hero, shows right side clearly ──
            CachedNetworkImage(
              imageUrl: _kHomeHeroImageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0.6, 0.0),
              placeholder: (context, url) =>
                  Container(color: const Color(0xFF6C5CE7)),
              errorWidget: (context, url, error) =>
                  Container(color: const Color(0xFF6C5CE7)),
            ),

            // ── Layer 2: Left-heavy gradient — text stays readable, right image shines ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    Color(0xEE1E1E1E), // dark left
                    Color(0xAA2A2A2A), // medium
                    Color(0x442A2A2A), // light fade
                    Color(0x002A2A2A), // fully transparent right
                  ],
                ),
              ),
            ),

            // ── Layer 3: Top vignette ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x88000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Layer 4: Bottom vignette so search bar pops ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Layer 5: Content ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      _HeaderIconBtn(
                        icon: Icons.menu_rounded,
                        onTap: onTapMenu,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onTapLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderIconBtn(
                        icon: Icons.notifications_none_rounded,
                        onTap: onTapNotifications,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Hero text — only left half, image visible right
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Find Your\nPerfect Property',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: -0.4,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Buy, Rent or Invest in the best\nproperties around you',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      shadows: const [
                        Shadow(color: Color(0x33000000), blurRadius: 6),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Search bar
                  GestureDetector(
                    onTap: onTapSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFAAAAAA),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search property name',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // GestureDetector(
                          //   onTap: onTapFilters,
                          //   child: Container(
                          //     width: 32,
                          //     height: 32,
                          //     decoration: BoxDecoration(
                          //       color: _kPrimary.withValues(alpha: 0.04),
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     child: const Icon(
                          //       Icons.tune_rounded,
                          //       color: _kPrimary,
                          //       size: 18,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends ConsumerWidget {
  final String currentMode;

  const _HomeDrawer({required this.currentMode});

  Widget _drawerTile({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF2EFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF5C46E8)
                        : const Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    final text = count.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5C46E8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAuthed = user != null;
    final owner = ref.watch(ownerProfileNotifierProvider).profile;

    final displayName = (owner?.name.trim().isNotEmpty ?? false)
        ? owner!.name.trim()
        : ((user == null || user.name.trim().isEmpty)
              ? 'Rahul Sharma'
              : user.name.trim());

    // Badges: if guest, show high fidelity mock numbers from user image, else show dynamic numbers.
    final enquiriesCount = isAuthed
        ? ref.watch(leadNotifierProvider).items.length
        : 28;
    final shortlistedCount = isAuthed ? ref.watch(favoritesProvider).length : 5;
    final myPropertiesCount = isAuthed
        ? ref.watch(propertyNotifierProvider).all.length
        : 12;
    // We can count contacted leads or just mock site visits
    final siteVisitsCount = isAuthed
        ? ref
              .watch(leadNotifierProvider)
              .items
              .where(
                (e) =>
                    e.status.toLowerCase() == 'contacted' ||
                    e.status.toLowerCase() == 'converted',
              )
              .length
        : 3;

    // Check if we are currently on Home tab (index 0)
    final currentNavIndex = ref.watch(navProvider);
    final isHomeSelected = currentNavIndex == 0;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Purple Profile Header Container
          Container(
            color: const Color(0xFF5C46E8),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button at top right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                // Profile Photo + Name/View Profile
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isAuthed) {
                      context.push(
                        '/login?from=${Uri.encodeComponent('/profile')}',
                      );
                    } else {
                      ref
                          .read(navProvider.notifier)
                          .goTo(3); // Go to Profile screen
                    }
                  },
                  child: Row(
                    children: [
                      // White circular border with custom grey icon placeholder inside
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFB0B0B0),
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  isAuthed ? 'View Profile' : 'View Profile',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 14,
                                ),
                              ],
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

          // Drawer Nav List Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // SECTION 1: Nav Items
                _drawerTile(
                  icon: Icon(
                    Icons.home_outlined,
                    color: isHomeSelected
                        ? const Color(0xFF5C46E8)
                        : const Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Home',
                  isSelected: isHomeSelected,
                  onTap: () {
                    ref.read(navProvider.notifier).goTo(0);
                    Navigator.of(context).pop();
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.apartment_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Buy Property',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'Any',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.key_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Rent Property',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'rent',
                        budget: const RangeValues(500, 5000),
                        propertyType: 'Any',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.hotel_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'PG / Co-living',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'rent',
                        budget: const RangeValues(500, 5000),
                        propertyType: 'PG',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Commercial',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'Commercial',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.landscape_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Land / Plot',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'Plot',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.domain_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'New Projects',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'New Project',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.construction_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Builder Projects',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'Any',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF2F4F7),
                  ),
                ),

                // SECTION 2: My Enquiries, Shortlisted, My Properties, Site Visits
                _drawerTile(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'My Enquiries',
                  trailing: _badge(enquiriesCount),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isAuthed) {
                      AppSnackbar.showError(
                        context,
                        'Please login to view enquiries',
                      );
                      context.push(
                        '/login?from=${Uri.encodeComponent('/leads')}',
                      );
                    } else {
                      context.push('/leads');
                    }
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Shortlisted',
                  trailing: _badge(shortlistedCount),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isAuthed) {
                      AppSnackbar.showError(
                        context,
                        'Please login to view saved',
                      );
                      context.push(
                        '/login?from=${Uri.encodeComponent('/favorites')}',
                      );
                    } else {
                      context.push('/favorites');
                    }
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.home_work_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'My Properties',
                  trailing: _badge(myPropertiesCount),
                  onTap: () {
                    ref
                        .read(navProvider.notifier)
                        .goTo(1); // Go to Properties tab
                    Navigator.of(context).pop();
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Site Visits',
                  trailing: _badge(siteVisitsCount),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isAuthed) {
                      AppSnackbar.showError(
                        context,
                        'Please login to view appointments',
                      );
                      context.push(
                        '/login?from=${Uri.encodeComponent('/leads')}',
                      );
                    } else {
                      context.push('/leads');
                    }
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF2F4F7),
                  ),
                ),

                // SECTION 3: My Offers, Alerts, Saved Searches, Recently Viewed
                _drawerTile(
                  icon: const Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'My Offers',
                  onTap: () {
                    Navigator.of(context).pop();
                    AppSnackbar.showMessage(
                      context,
                      'No offers submitted yet.',
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Alerts',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/notifications');
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.saved_search_rounded,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Saved Searches',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/name-search',
                      extra: NameSearchArgs(mode: currentMode),
                    );
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Recently Viewed',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/properties');
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF2F4F7),
                  ),
                ),

                // SECTION 4: Settings, Help & Support, Logout
                _drawerTile(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isAuthed) {
                      AppSnackbar.showError(
                        context,
                        'Please login to view settings',
                      );
                      context.push(
                        '/login?from=${Uri.encodeComponent('/profile')}',
                      );
                    } else {
                      context.push('/profile');
                    }
                  },
                ),
                _drawerTile(
                  icon: const Icon(
                    Icons.headset_mic_outlined,
                    color: Color(0xFF627D98),
                    size: 22,
                  ),
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Help & Support',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        content: const Text(
                          'For support queries, please contact support@propertysearch.com or call our toll-free number.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (isAuthed)
                  _drawerTile(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF5C46E8),
                      size: 22,
                    ),
                    title: 'Logout',
                    onTap: () async {
                      Navigator.of(context).pop();
                      final router = GoRouter.of(context);
                      await ref.read(authProvider.notifier).logout();
                      router.go('/login');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  QUICK ACTIONS
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onItemTap;

  const _QuickActions({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final items = <_QAItem>[
      _QAItem(
        asset: 'assets/icons/buy-home.png',
        label: 'Buy',
        onTap: () => onItemTap('Buy'),
      ),
      _QAItem(
        asset: 'assets/icons/for-rent.png',
        label: 'Rent',
        onTap: () => onItemTap('Rent'),
      ),
      _QAItem(
        asset: 'assets/icons/pg.png',
        label: 'PG / Living',
        onTap: () => onItemTap('PG / Living'),
      ),
      _QAItem(
        asset: 'assets/icons/commercial.png',
        label: 'Commercial',
        onTap: () => onItemTap('Commercial'),
      ),
      _QAItem(
        asset: 'assets/icons/Plot.png',
        label: 'Land/Plot',
        onTap: () => onItemTap('Land/Plot'),
      ),
      _QAItem(
        asset: 'assets/icons/newProject.png',
        label: 'New Projects',
        onTap: () => onItemTap('New Projects'),
      ),
      _QAItem(
        asset: 'assets/icons/builder.png',
        label: 'Builders',
        onTap: () => onItemTap('Builders'),
      ),
      _QAItem(
        asset: 'assets/icons/more.png',
        label: 'More',
        onTap: () => onItemTap('More'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: items
                .take(4)
                .map((i) => Expanded(child: _QACell(item: i)))
                .toList(),
          ),
          const SizedBox(height: 2),
          Row(
            children: items
                .skip(4)
                .map((i) => Expanded(child: _QACell(item: i)))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Row(
          //   children: [
          //     _ModePill(
          //       label: 'Rent',
          //       selected: mode == 'rent',
          //       onTap: () => onModeChanged('rent'),
          //     ),
          //     const SizedBox(width: 10),
          //     _ModePill(
          //       label: 'Buy',
          //       selected: mode != 'rent',
          //       onTap: () => onModeChanged('buy'),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _QAItem {
  final String asset;
  final String label;
  final VoidCallback onTap;
  const _QAItem({
    required this.asset,
    required this.label,
    required this.onTap,
  });
}

class _QACell extends StatelessWidget {
  final _QAItem item;
  const _QACell({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(13),
              //   border: Border.all(color: _kBorder),
              // ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(item.asset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  POPULAR SEARCHES
// ─────────────────────────────────────────────────────────────
class _PopularSearches extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTapItem;
  const _PopularSearches({required this.items, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Searches',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => onTapItem(items[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  items[i],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextMid,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

// ─────────────────────────────────────────────────────────────
//  CREATE LEAD CTA
// ─────────────────────────────────────────────────────────────
class _CreateLeadBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _CreateLeadBanner({required this.onTap});

  @override
  State<_CreateLeadBanner> createState() => _CreateLeadBannerState();
}

class _CreateLeadBannerState extends State<_CreateLeadBanner> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = const <({String title, String subtitle})>[
      (
        title: 'Create Lead',
        subtitle: 'Fill details now — login required before submit',
      ),
      (
        title: 'Quick Enquiry',
        subtitle: 'Capture customer requirement in seconds',
      ),
      (
        title: 'Follow Up Faster',
        subtitle: 'Keep everything organised in one place',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CarouselSlider.builder(
          itemCount: slides.length,
          itemBuilder: (context, index, realIndex) {
            final slide = slides[index];
            return GestureDetector(
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/leadBanner.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _kPrimary.withValues(alpha: 0.25)),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.58),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.6, -0.2),
                          radius: 1.15,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slide.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: List.generate(slides.length, (i) {
                                  final active = i == _index;
                                  return AnimatedContainer(
                                    duration: 220.ms,
                                    margin: const EdgeInsets.only(right: 6),
                                    height: 6,
                                    width: active ? 18 : 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Open',
                            style: TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: 120,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: 4.seconds,
            autoPlayAnimationDuration: 520.ms,
            enableInfiniteScroll: slides.length > 1,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.onSeeAll, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kTextDark,
              ),
            ),
          ),
          if (trailing != null) ...[trailing!],
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BUILDER CHIP
// ─────────────────────────────────────────────────────────────
class _BuilderChip extends StatelessWidget {
  final String asset;
  const _BuilderChip({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 92,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              color: _kTextMid,
              size: 22,
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: _kPrimary,
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
                color: _kTextMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom navigation removed (now managed via Drawer).

// ─────────────────────────────────────────────────────────────
//  LOCATION SHEET  (logic fully unchanged)
// ─────────────────────────────────────────────────────────────
class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Enter city/locality',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(locationProvider.notifier)
                              .fetchCurrent(),
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.error!.replaceFirst('Exception: ', ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final loc in state.saved.take(8))
                    ActionChip(
                      label: Text(loc),
                      onPressed: () async {
                        await ref
                            .read(locationProvider.notifier)
                            .setManual(loc);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(locationProvider.notifier)
                        .setManual(_controller.text);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use this location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPropertyCard extends ConsumerWidget {
  final Property p;
  final VoidCallback onTap;

  const _FeaturedPropertyCard({required this.p, required this.onTap});

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

    String formatPrice(int price, String type) {
      if (type == 'rent') {
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

    final specs = getPropertySpecs(p);
    const fallbackImage =
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: p.images.isEmpty
                        ? fallbackImage
                        : p.images.first.trim(),
                    height: 115,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.black12),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.black12),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: toggleFavorite,
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? Colors.pinkAccent
                              : const Color(0xFF5C46E8),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(p.price, p.type),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${specs.sqft.replaceAll(RegExp(r'\s*sqft'), '')} sqft  •  ${specs.bedrooms.replaceAll(RegExp(r'\s*Bed'), '')} Bed  •  ${specs.bathrooms.replaceAll(RegExp(r'\s*Bath'), '')} Bath',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
