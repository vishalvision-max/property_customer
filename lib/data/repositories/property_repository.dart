import '../models/property.dart';
import '../services/property_service.dart';

class PropertyRepository {
  final PropertyService _service;

  PropertyRepository(this._service);

  Future<List<Property>> fetchAll() => _service.fetchProperties();

  Future<List<Property>> fetchFiltered({
    int? categoryId,
    String? city,
    int? minPrice,
    int? maxPrice,
    String? type,
    String? sortBy,
  }) => _service.fetchFiltered(
    categoryId: categoryId,
    city: city,
    minPrice: minPrice,
    maxPrice: maxPrice,
    type: type,
    sortBy: sortBy,
  );

  Future<Property> fetchDetails(String id) => _service.fetchDetails(id);

  Future<List<String>> fetchPropertyImages(String id) =>
      _service.fetchPropertyImages(id);

  Future<List<Property>> fetchPopular() => _service.fetchPopular();

  Future<List<Property>> fetchNearby({
    required double lat,
    required double lng,
    int radius = 100,
  }) => _service.fetchNearby(lat: lat, lng: lng, radius: radius);

  Future<List<Property>> fetchRecommendations({required String token}) =>
      _service.fetchRecommendations(token: token);

  Future<List<Property>> fetchAllOwnerProperties({required String token}) =>
      _service.fetchAllOwnerProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchAllOwnerPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchAllOwnerPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchTwoBhkProperties({required String token}) =>
      _service.fetchTwoBhkProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchTwoBhkPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchTwoBhkPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchFlatsUnderFiftyLakh({required String token}) =>
      _service.fetchFlatsUnderFiftyLakh(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFlatsUnderFiftyLakhPaged({required String token, int page = 1}) =>
      _service.fetchFlatsUnderFiftyLakhPaged(token: token, page: page);

  Future<List<Property>> fetchReadyToMoveProperties({required String token}) =>
      _service.fetchReadyToMoveProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchReadyToMovePropertiesPaged({required String token, int page = 1}) =>
      _service.fetchReadyToMovePropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchFurnishedProperties({required String token}) =>
      _service.fetchFurnishedProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchFurnishedPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchFurnishedPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchGatedSocietyProperties({required String token}) =>
      _service.fetchGatedSocietyProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchGatedSocietyPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchGatedSocietyPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchStudioApartmentProperties({required String token}) =>
      _service.fetchStudioApartmentProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchStudioApartmentPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchStudioApartmentPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchRentProperties({required String token}) =>
      _service.fetchRentProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchRentPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchRentPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchBuyProperties({required String token}) =>
      _service.fetchBuyProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchBuyPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchBuyPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchPgProperties({required String token}) =>
      _service.fetchPgProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchPgPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchPgPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchCoLivingProperties({required String token}) =>
      _service.fetchCoLivingProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCoLivingPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchCoLivingPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchCommercialProperties({required String token}) =>
      _service.fetchCommercialProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchCommercialPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchCommercialPropertiesPaged(token: token, page: page);

  Future<List<Property>> fetchLandPlotProperties({required String token}) =>
      _service.fetchLandPlotProperties(token: token);

  Future<({List<Property> items, bool hasMore, int currentPage})>
  fetchLandPlotPropertiesPaged({required String token, int page = 1}) =>
      _service.fetchLandPlotPropertiesPaged(token: token, page: page);

  Future<dynamic> fetchHeatmap() => _service.fetchHeatmap();

  Future<List<Property>> search({
    required String mode,
    required BudgetRange budgetRange,
    String? propertyType,
    List<String> amenities = const [],
    String? locationQuery,
    String? sortBy,
  }) => _service.search(
    mode: mode,
    budgetRange: budgetRange,
    propertyType: propertyType,
    amenities: amenities,
    locationQuery: locationQuery,
    sortBy: sortBy,
  );

  Future<List<Property>> searchByKeyword({
    required String keyword,
    // String? type,
  }) => _service.searchByKeyword(keyword: keyword);
}
