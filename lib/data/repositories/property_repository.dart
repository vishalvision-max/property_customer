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
