import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';
import '../data/models/property.dart';
import 'property_provider.dart';
import 'app_providers.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  // Short-lived local overrides map
  final Map<String, ({bool isFavorited, DateTime at})> _localOverrides = {};
  static const Duration _kOverrideTtl = Duration(seconds: 20);

  @override
  Set<String> build() {
    return const <String>{};
  }

  void _setOverride(String id, bool isFavorited) {
    _localOverrides[id] = (isFavorited: isFavorited, at: DateTime.now());
  }

  void _clearOverride(String id) {
    _localOverrides.remove(id);
  }

  Set<String> _applyOverrides(Set<String> base) {
    if (_localOverrides.isEmpty) return base;
    final now = DateTime.now();
    final next = {...base};
    final expired = <String>[];

    _localOverrides.forEach((id, entry) {
      if (now.difference(entry.at) > _kOverrideTtl) {
        expired.add(id);
        return;
      }
      if (entry.isFavorited) {
        next.add(id);
      } else {
        next.remove(id);
      }
    });

    for (final id in expired) {
      _localOverrides.remove(id);
    }
    return next;
  }

  Future<void> load() async {
    final storage = ref.read(localStorageProvider);
    state = await storage.getFavorites();
    if (kIsWeb) return;

    final token = ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) return;
    try {
      final favoritesService = ref.read(favoritesServiceProvider);
      final remote = await favoritesService.fetchFavoriteIds(token: token);
      state = _applyOverrides(remote);
      await storage.saveFavorites(state);

      // Pre-populate nested favoritable property objects into the property provider's cache!
      final rawProps = await favoritesService.fetchFavoriteProperties(token: token);
      if (rawProps.isNotEmpty) {
        final propNotifier = ref.read(propertyNotifierProvider.notifier);
        final service = ref.read(propertyServiceProvider);
        final List<Property> parsed = [];
        for (final raw in rawProps) {
          try {
            parsed.add(service.propertyFromApiJson(raw));
          } catch (_) {}
        }
        if (parsed.isNotEmpty) {
          propNotifier.upsertMany(parsed);
        }
      }
    } catch (_) {
      // Keep local cache if remote sync fails.
    }
  }

  Future<void> refresh() => load();

  Future<void> removeRemote({required String id}) async {
    final storage = ref.read(localStorageProvider);
    if (kIsWeb) {
      final next = {...state}..remove(id);
      state = next;
      await storage.saveFavorites(state);
      return;
    }

    final token = ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) {
      final next = {...state}..remove(id);
      state = next;
      await storage.saveFavorites(state);
      return;
    }

    final wasFav = state.contains(id);
    _setOverride(id, false);
    final optimistic = {...state}..remove(id);
    state = optimistic;
    await storage.saveFavorites(state);

    try {
      final favoritesService = ref.read(favoritesServiceProvider);
      await favoritesService.delete(token: token, id: id);
      _clearOverride(id);
    } catch (e) {
      if (wasFav) {
        final rollback = {...state}..add(id);
        state = rollback;
        await storage.saveFavorites(state);
      }
      _setOverride(id, wasFav);
      rethrow;
    }
  }

  Future<void> toggle(String propertyId) async {
    final storage = ref.read(localStorageProvider);
    final next = {...state};
    if (next.contains(propertyId)) {
      next.remove(propertyId);
    } else {
      next.add(propertyId);
    }
    state = next;
    await storage.saveFavorites(state);
  }

  Future<void> toggleRemote({
    required String type,
    required String id,
  }) async {
    if (kIsWeb) {
      await toggle(id);
      return;
    }

    final token = ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) {
      await toggle(id);
      return;
    }

    final wasFav = state.contains(id);
    final optimistic = {...state};
    if (wasFav) {
      optimistic.remove(id);
    } else {
      optimistic.add(id);
    }
    _setOverride(id, !wasFav);
    state = optimistic;
    final storage = ref.read(localStorageProvider);
    await storage.saveFavorites(state);

    try {
      final favoritesService = ref.read(favoritesServiceProvider);
      final result =
          await favoritesService.toggle(token: token, type: type, id: id);
      if (result.isFavorited != null) {
        final reconciled = {...state};
        if (result.isFavorited!) {
          reconciled.add(id);
        } else {
          reconciled.remove(id);
        }
        state = reconciled;
        await storage.saveFavorites(state);
        _setOverride(id, result.isFavorited!);
        _clearOverride(id);
      }
    } catch (e) {
      final rollback = {...state};
      if (wasFav) {
        rollback.add(id);
      } else {
        rollback.remove(id);
      }
      state = rollback;
      await storage.saveFavorites(state);
      _setOverride(id, wasFav);
      rethrow;
    }
  }

  bool isFavorite(String id) => state.contains(id);
}
