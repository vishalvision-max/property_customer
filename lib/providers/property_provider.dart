import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/property.dart';
import '../data/repositories/property_repository.dart';
import '../data/services/property_service.dart';
import 'app_providers.dart';

class PropertyState {
  final bool isLoading;
  final List<Property> all;
  final List<Property> featured;
  final List<Property> recommended;
  final List<Property> nearby;
  final Property? selected;
  final String? error;

  const PropertyState({
    required this.isLoading,
    required this.all,
    required this.featured,
    required this.recommended,
    required this.nearby,
    required this.selected,
    required this.error,
  });

  factory PropertyState.initial() => const PropertyState(
    isLoading: false,
    all: [],
    featured: [],
    recommended: [],
    nearby: [],
    selected: null,
    error: null,
  );

  PropertyState copyWith({
    bool? isLoading,
    List<Property>? all,
    List<Property>? featured,
    List<Property>? recommended,
    List<Property>? nearby,
    Object? selected = _unset,
    String? error,
  }) {
    return PropertyState(
      isLoading: isLoading ?? this.isLoading,
      all: all ?? this.all,
      featured: featured ?? this.featured,
      recommended: recommended ?? this.recommended,
      nearby: nearby ?? this.nearby,
      selected: selected == _unset ? this.selected : selected as Property?,
      error: error,
    );
  }

  static const Object _unset = Object();
}

class PropertyNotifier extends StateNotifier<PropertyState> {
  final PropertyRepository _repo;
  PropertyNotifier(this._repo) : super(PropertyState.initial());

  Future<void> loadHome({
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // /nearby is the only endpoint currently returning real data.
      // Fall back to fetchAll if no coordinates.
      List<Property> all;
      if (lat != null && lng != null) {
        all = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        all = await _repo.fetchAll();
      }

      List<Property> recommendations = const [];
      if (token != null && token.trim().isNotEmpty) {
        try {
          recommendations = await _repo.fetchRecommendations(
            token: token.trim(),
          );
        } catch (_) {
          recommendations = const [];
        }
      }

      state = state.copyWith(
        isLoading: false,
        all: all,
        featured: all.take(4).toList(growable: false),
        recommended: recommendations.isEmpty
            ? (all.length > 1 ? all.skip(1).toList(growable: false) : all)
            : recommendations,
        nearby: lat != null && lng != null ? all : state.nearby,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload home data filtered by [type] ('rent' or 'buy').
  /// Called when the user switches the Rent/Buy tab so each section
  /// shows only properties matching the selected mode.
  ///
  /// Strategy: the main /properties endpoint currently returns 0 results
  /// (backend issue). The /nearby endpoint is the only one returning real
  /// data, so we use it as the primary source and filter by type client-side.
  Future<void> loadHomeForMode({
    required String type,
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use nearby as primary source when coordinates are available,
      // otherwise fall back to the main endpoint.
      List<Property> allProps = const [];

      if (lat != null && lng != null) {
        allProps = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        allProps = await _repo.fetchAll();
      }

      // Filter by the selected mode client-side.
      // Backend type field: 'rent' stays 'rent', 'sale' is normalised to 'buy'.
      final filtered = allProps
          .where((p) => p.type == type)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        all: filtered,
        featured: filtered.take(4).toList(growable: false),
        recommended: filtered.length > 1
            ? filtered.skip(1).toList(growable: false)
            : filtered,
        nearby: lat != null && lng != null ? filtered : state.nearby,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Property? getById(String id) {
    try {
      return state.all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void upsertMany(List<Property> properties) {
    final nextAll = [...state.all];
    for (final p in properties) {
      final idx = nextAll.indexWhere((e) => e.id == p.id);
      if (idx >= 0) {
        nextAll[idx] = p;
      } else {
        nextAll.add(p);
      }
    }
    state = state.copyWith(all: nextAll);
  }

  Future<List<Property>> search({
    required String mode,
    required BudgetRange budgetRange,
    String? propertyType,
    List<String> amenities = const [],
    String? locationQuery,
    String? sortBy,
  }) => _repo.search(
    mode: mode,
    budgetRange: budgetRange,
    propertyType: propertyType,
    amenities: amenities,
    locationQuery: locationQuery,
    sortBy: sortBy,
  );

  /// Fetch properties for a quick-action tab (Rent, Buy, PG, Commercial, etc.).
  /// Uses /nearby (or /properties as fallback) as the data source and filters
  /// client-side, because the backend /properties endpoint returns 0 results
  /// when type/price filters are applied.
  Future<List<Property>> fetchForType({
    required String mode,
    String? propertyType, // optional sub-type filter (client-side)
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    List<Property> all;
    if (lat != null && lng != null) {
      all = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
    } else {
      all = await _repo.fetchAll();
    }

    return all
        .where((p) {
          final typeOk = p.type == mode;
          final subTypeOk = (propertyType == null || propertyType == 'Any')
              ? true
              : (p.propertyKind.toLowerCase().contains(propertyType.toLowerCase()) || 
                 p.name.toLowerCase().contains(propertyType.toLowerCase()));
          return typeOk && subTypeOk;
        })
        .toList(growable: false);
  }

  Future<List<Property>> searchByName({
    required String mode,
    required String query,
  }) async {
    final q = query.trim();
    // Delegate to the backend keyword search so results are not limited
    // to what is already cached locally.
    return _repo.searchByKeyword(keyword: q);
  }

  Future<Property> fetchDetails(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final p = await _repo.fetchDetails(id);
      // Upsert into `all` so other screens can use it too.
      final nextAll = [...state.all];
      final idx = nextAll.indexWhere((e) => e.id == p.id);
      if (idx >= 0) {
        nextAll[idx] = p;
      } else {
        nextAll.add(p);
      }
      state = state.copyWith(
        isLoading: false,
        all: nextAll,
        selected: p,
        error: null,
      );
      return p;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> loadNearby({
    required double lat,
    required double lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      state = state.copyWith(isLoading: false, nearby: items, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<Property>> fetchTwoBhkProperties(String token) {
    return _repo.fetchTwoBhkProperties(token: token);
  }

  Future<List<Property>> fetchFlatsUnderFiftyLakh(String token) {
    return _repo.fetchFlatsUnderFiftyLakh(token: token);
  }

  Future<List<Property>> fetchReadyToMoveProperties(String token) {
    return _repo.fetchReadyToMoveProperties(token: token);
  }

  Future<List<Property>> fetchFurnishedProperties(String token) {
    return _repo.fetchFurnishedProperties(token: token);
  }

  Future<List<Property>> fetchGatedSocietyProperties(String token) {
    return _repo.fetchGatedSocietyProperties(token: token);
  }

  Future<List<Property>> fetchStudioApartmentProperties(String token) {
    return _repo.fetchStudioApartmentProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchTwoBhkPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchTwoBhkPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFlatsUnderFiftyLakhPaged(String token, {int page = 1}) {
    return _repo.fetchFlatsUnderFiftyLakhPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchReadyToMovePropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchReadyToMovePropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFurnishedPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchFurnishedPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchGatedSocietyPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchGatedSocietyPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchStudioApartmentPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchStudioApartmentPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchRentProperties(String token) {
    return _repo.fetchRentProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchRentPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchRentPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchBuyProperties(String token) {
    return _repo.fetchBuyProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchBuyPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchBuyPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchPgProperties(String token) {
    return _repo.fetchPgProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchPgPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchPgPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchCoLivingProperties(String token) {
    return _repo.fetchCoLivingProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCoLivingPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchCoLivingPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchCommercialProperties(String token) {
    return _repo.fetchCommercialProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCommercialPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchCommercialPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchLandPlotProperties(String token) {
    return _repo.fetchLandPlotProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchLandPlotPropertiesPaged(String token, {int page = 1}) {
    return _repo.fetchLandPlotPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchAllOwnerProperties(String token) {
    return _repo.fetchAllOwnerProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchAllOwnerPropertiesPaged(String token, {int page = 1, String? city}) {
    return _repo.fetchAllOwnerPropertiesPaged(token: token, page: page, city: city);
  }
}


final propertyProvider = StateNotifierProvider<PropertyNotifier, PropertyState>(
  (ref) => PropertyNotifier(ref.watch(propertyRepositoryProvider)),
);
