import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../search/name_search_args.dart';
import '../search/search_args.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

/// The "Properties" tab — shows all nearby/available properties with a
/// search bar and filter button at the top.
class PropertiesTabScreen extends ConsumerStatefulWidget {
  const PropertiesTabScreen({super.key});

  @override
  ConsumerState<PropertiesTabScreen> createState() =>
      _PropertiesTabScreenState();
}

class _PropertiesTabScreenState extends ConsumerState<PropertiesTabScreen> {
  Future<List<Property>>? _future;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  void _load() {
    final loc = ref.read(locationProvider);
    setState(() {
      _future = ref
          .read(propertyProvider.notifier)
          .fetchForType(
            mode: 'rent', // default — shows all rent; user can filter
            lat: loc.lat,
            lng: loc.lng,
          )
          .then((rent) async {
            // Also fetch buy and merge for a full "all properties" view
            final buy = await ref
                .read(propertyProvider.notifier)
                .fetchForType(mode: 'buy', lat: loc.lat, lng: loc.lng);
            return [...rent, ...buy];
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Properties',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.tune_rounded, color: _kPrimary),
                tooltip: 'Filters',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: GestureDetector(
                  onTap: () => context.push(
                    '/name-search',
                    extra: const NameSearchArgs(mode: 'rent'),
                  ),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: _kTextMid,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Search properties…',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter chips ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All', onTap: _load),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Rent',
                    onTap: () {
                      final loc = ref.read(locationProvider);
                      setState(() {
                        _future = ref
                            .read(propertyProvider.notifier)
                            .fetchForType(
                              mode: 'rent',
                              lat: loc.lat,
                              lng: loc.lng,
                            );
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Buy',
                    onTap: () {
                      final loc = ref.read(locationProvider);
                      setState(() {
                        _future = ref
                            .read(propertyProvider.notifier)
                            .fetchForType(
                              mode: 'buy',
                              lat: loc.lat,
                              lng: loc.lng,
                            );
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'PG / Living',
                    onTap: () => context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'rent',
                        budget: const RangeValues(500, 5000),
                        propertyType: 'PG',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Commercial',
                    onTap: () => context.push(
                      '/properties',
                      extra: SearchArgs(
                        mode: 'buy',
                        budget: const RangeValues(0, 3000000),
                        propertyType: 'Commercial',
                        amenities: const [],
                        locationQuery: '',
                        fromTab: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── List ──
          SliverFillRemaining(
            child: FutureBuilder<List<Property>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const ShimmerList();
                }
                final items = snap.data ?? const <Property>[];
                if (items.isEmpty) {
                  return EmptyState(
                    title: 'No properties found',
                    message: 'Try a different filter or check back later.',
                    asset: 'assets/illustrations/empty_search.svg',
                    action: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return PropertyCard(
                      property: p,
                      onTap: () => context.push('/property/${p.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _kTextDark,
          ),
        ),
      ),
    );
  }
}
