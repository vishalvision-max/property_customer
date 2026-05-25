import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/favorites_service.dart';
import '../data/services/local_storage_service.dart';
import 'auth_provider.dart';
import 'app_providers.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final LocalStorageService _storage;
  final FavoritesService _favoritesService;
  final Ref _ref;

  FavoritesNotifier(this._storage, this._favoritesService, this._ref)
      : super(const <String>{});

  /// When a user taps like/unlike we optimistically update UI.
  /// Some backends can be eventually-consistent or cached for a short time, so
  /// a subsequent `load()` may temporarily return stale favorite ids and would
  /// flip the UI back. Keep a short-lived local override per id to prevent
  /// this "auto-like again" behavior.
  static const Duration _kOverrideTtl = Duration(seconds: 20);
  final Map<String, ({bool isFavorited, DateTime at})> _localOverrides = {};

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
    state = await _storage.getFavorites();
    final token = _ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) return;
    try {
      final remote = await _favoritesService.fetchFavoriteIds(token: token);
      state = _applyOverrides(remote);
      await _storage.saveFavorites(state);
    } catch (_) {
      // Keep local cache if remote sync fails.
    }
  }

  Future<void> refresh() => load();

  Future<void> removeRemote({required String id}) async {
    final token = _ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) {
      final next = {...state}..remove(id);
      state = next;
      await _storage.saveFavorites(state);
      return;
    }

    final wasFav = state.contains(id);
    _setOverride(id, false);
    final optimistic = {...state}..remove(id);
    state = optimistic;
    await _storage.saveFavorites(state);

    try {
      await _favoritesService.delete(token: token, id: id);
      _clearOverride(id);
    } catch (e) {
      if (wasFav) {
        final rollback = {...state}..add(id);
        state = rollback;
        await _storage.saveFavorites(state);
      }
      _setOverride(id, wasFav);
      rethrow;
    }
  }

  Future<void> toggle(String propertyId) async {
    final next = {...state};
    if (next.contains(propertyId)) {
      next.remove(propertyId);
    } else {
      next.add(propertyId);
    }
    state = next;
    await _storage.saveFavorites(state);
  }

  Future<void> toggleRemote({
    required String type,
    required String id,
  }) async {
    final token = _ref.read(authProvider).user?.token;
    if (token == null || token.trim().isEmpty) {
      // UI already guards this, but keep this safe for programmatic calls.
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
    await _storage.saveFavorites(state);

    try {
      final result =
          await _favoritesService.toggle(token: token, type: type, id: id);
      if (result.isFavorited != null) {
        final reconciled = {...state};
        if (result.isFavorited!) {
          reconciled.add(id);
        } else {
          reconciled.remove(id);
        }
        state = reconciled;
        await _storage.saveFavorites(state);
        _setOverride(id, result.isFavorited!);
        _clearOverride(id);
      }
    } catch (e) {
      // Roll back local state if API call failed.
      final rollback = {...state};
      if (wasFav) {
        rollback.add(id);
      } else {
        rollback.remove(id);
      }
      state = rollback;
      await _storage.saveFavorites(state);
      _setOverride(id, wasFav);
      rethrow;
    }
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(
    ref.watch(localStorageProvider),
    ref.watch(favoritesServiceProvider),
    ref,
  ),
);
