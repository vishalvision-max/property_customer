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
      appBar: AppBar(title: const Text('Favorites')),
      body: favIds.isEmpty
          ? const EmptyState(
              title: 'No favorites yet',
              message: 'Tap the heart on a property to save it here.',
              asset: 'assets/illustrations/empty_favorites.svg',
            )
          : FutureBuilder<List<Property>>(
              future: _loadFavorites(favIds),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final favs = snap.data ?? const <Property>[];
                if (favs.isEmpty) {
                  return const EmptyState(
                    title: 'No favorites found',
                    message: 'Pull to refresh or try again later.',
                    asset: 'assets/illustrations/empty_favorites.svg',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: favs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    );
  }
}
