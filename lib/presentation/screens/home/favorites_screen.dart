import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  // Key used to force a rebuild of the FutureBuilder on pull-to-refresh.
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(favoritesProvider.notifier).load();
      }
    });
  }

  Future<void> _onRefresh() async {
    // 1. Re-sync favorites IDs from the server.
    await ref.read(favoritesProvider.notifier).refresh();
    // 2. Bump the key so FutureBuilder re-runs _loadFavorites.
    if (mounted) setState(() => _refreshKey++);
  }

  Future<List<Property>> _loadFavorites(List<String> ids) async {
    final notifier = ref.read(propertyProvider.notifier);
    final out = <Property>[];
    for (final id in ids) {
      final cached = notifier.getById(id);
      if (cached != null) {
        out.add(cached);
        continue;
      }
      try {
        out.add(await notifier.fetchDetails(id));
      } catch (_) {
        // Ignore individual failures; keep rendering remaining favorites.
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider).toList()..sort();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Favorites')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF6C5CE7),
        child: favIds.isEmpty
            // Wrap empty state in a scrollable so pull-to-refresh still works.
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: const EmptyState(
                      title: 'No favorites yet',
                      message: 'Tap the heart on a property to save it here.',
                      asset: 'assets/illustrations/empty_favorites.svg',
                    ),
                  ),
                ),
              )
            : FutureBuilder<List<Property>>(
                // _refreshKey changes force a fresh fetch on pull-to-refresh.
                key: ValueKey(_refreshKey),
                future: _loadFavorites(favIds),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final favs = snap.data ?? const <Property>[];
                  if (favs.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: const EmptyState(
                            title: 'No favorites found',
                            message: 'Pull down to refresh.',
                            asset: 'assets/illustrations/empty_favorites.svg',
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    // AlwaysScrollableScrollPhysics keeps pull-to-refresh
                    // working even when there are only 1–2 items.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: favs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = favs[i];
                      return PropertyCard(
                        property: p,
                        onTap: () => context.push('/property/${p.id}'),
                        videoLoop: false,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
