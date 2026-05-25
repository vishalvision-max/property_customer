import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/lead_repository.dart';
import '../data/repositories/owner_repository.dart';
import '../data/repositories/property_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/favorites_service.dart';
import '../data/services/google_geocoding_service.dart';
import '../data/services/video_cache_service.dart';
import '../data/services/lead_service.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/owner_service.dart';
import '../data/services/property_service.dart';

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final propertyServiceProvider = Provider<PropertyService>(
  (ref) => PropertyService(),
);
final leadServiceProvider = Provider<LeadService>((ref) => LeadService());
final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => FavoritesService(),
);

final ownerServiceProvider = Provider<OwnerService>((ref) => OwnerService());

final googleGeocodingServiceProvider = Provider<GoogleGeocodingService>(
  (ref) =>
      GoogleGeocodingService(apiKey: "AIzaSyB9zroafCQGFNKoU1g5-ScptQBJo2FgpKw"),
);

final videoCacheServiceProvider = Provider<VideoCacheService>(
  (ref) => VideoCacheService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(localStorageProvider),
  ),
);

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => PropertyRepository(ref.watch(propertyServiceProvider)),
);

final leadRepositoryProvider = Provider<LeadRepository>(
  (ref) => LeadRepository(ref.watch(leadServiceProvider)),
);

final ownerRepositoryProvider = Provider<OwnerRepository>(
  (ref) => OwnerRepository(ref.watch(ownerServiceProvider)),
);

/// Lazily fetches and caches the image URLs for a single property by ID.
/// Used by PropertyCard when the list endpoint returns images: null.
final propertyImagesProvider = FutureProvider.family<List<String>, String>((
  ref,
  propertyId,
) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.fetchPropertyImages(propertyId);
});
