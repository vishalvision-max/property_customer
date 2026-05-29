import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/property.dart';
import '../data/services/property_service.dart';
import 'app_providers.dart';

part 'property_provider.freezed.dart';
part 'property_provider.g.dart';

@freezed
class PropertyState with _$PropertyState {
  const factory PropertyState({
    required bool isLoading,
    required List<Property> all,
    required List<Property> featured,
    required List<Property> recommended,
    required List<Property> nearby,
    required Property? selected,
    required String? error,
  }) = _PropertyState;

  factory PropertyState.initial() => const PropertyState(
        isLoading: false,
        all: [],
        featured: [],
        recommended: [],
        nearby: [],
        selected: null,
        error: null,
      );
}

@riverpod
class PropertyNotifier extends _$PropertyNotifier {
  @override
  PropertyState build() {
    return PropertyState.initial();
  }

  Future<void> loadHome({
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      List<Property> all;
      if (lat != null && lng != null) {
        all = await repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        all = await repo.fetchAll();
      }

      List<Property> recommendations = const [];
      if (token != null && token.trim().isNotEmpty) {
        try {
          recommendations = await repo.fetchRecommendations(
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

  Future<void> loadHomeForMode({
    required String type,
    String? token,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      List<Property> allProps = const [];

      if (lat != null && lng != null) {
        allProps = await repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      } else {
        allProps = await repo.fetchAll();
      }

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
  }) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.search(
      mode: mode,
      budgetRange: budgetRange,
      propertyType: propertyType,
      amenities: amenities,
      locationQuery: locationQuery,
      sortBy: sortBy,
    );
  }

  Future<List<Property>> fetchForType({
    required String mode,
    String? propertyType,
    double? lat,
    double? lng,
    int radius = 100,
  }) async {
    final repo = ref.read(propertyRepositoryProvider);
    List<Property> all;
    if (lat != null && lng != null) {
      all = await repo.fetchNearby(lat: lat, lng: lng, radius: radius);
    } else {
      all = await repo.fetchAll();
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
    final repo = ref.read(propertyRepositoryProvider);
    return repo.searchByKeyword(keyword: q);
  }

  Future<Property> fetchDetails(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final p = await repo.fetchDetails(id);
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
      final repo = ref.read(propertyRepositoryProvider);
      final items = await repo.fetchNearby(lat: lat, lng: lng, radius: radius);
      state = state.copyWith(isLoading: false, nearby: items, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<Property>> fetchTwoBhkProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchTwoBhkProperties(token: token);
  }

  Future<List<Property>> fetchFlatsUnderFiftyLakh(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchFlatsUnderFiftyLakh(token: token);
  }

  Future<List<Property>> fetchReadyToMoveProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchReadyToMoveProperties(token: token);
  }

  Future<List<Property>> fetchFurnishedProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchFurnishedProperties(token: token);
  }

  Future<List<Property>> fetchGatedSocietyProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchGatedSocietyProperties(token: token);
  }

  Future<List<Property>> fetchStudioApartmentProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchStudioApartmentProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchTwoBhkPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchTwoBhkPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFlatsUnderFiftyLakhPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchFlatsUnderFiftyLakhPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchReadyToMovePropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchReadyToMovePropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFurnishedPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchFurnishedPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchGatedSocietyPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchGatedSocietyPropertiesPaged(token: token, page: page);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchStudioApartmentPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchStudioApartmentPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchRentProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchRentProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchRentPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchRentPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchBuyProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchBuyProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchBuyPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchBuyPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchPgProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchPgProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchPgPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchPgPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchCoLivingProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchCoLivingProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCoLivingPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchCoLivingPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchCommercialProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchCommercialProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCommercialPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchCommercialPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchLandPlotProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchLandPlotProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchLandPlotPropertiesPaged(String token, {int page = 1}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchLandPlotPropertiesPaged(token: token, page: page);
  }

  Future<List<Property>> fetchAllOwnerProperties(String token) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchAllOwnerProperties(token: token);
  }

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchAllOwnerPropertiesPaged(String token, {int page = 1, String? city}) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.fetchAllOwnerPropertiesPaged(token: token, page: page, city: city);
  }

  Future<void> scheduleVisit({
    required String token,
    required String propertyId,
    required String userId,
    required String date,
    required String time,
  }) {
    final repo = ref.read(propertyRepositoryProvider);
    return repo.scheduleVisit(
      token: token,
      propertyId: propertyId,
      userId: userId,
      date: date,
      time: time,
    );
  }
}
