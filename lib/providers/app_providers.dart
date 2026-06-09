import 'package:riverpod_annotation/riverpod_annotation.dart';
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
import 'auth_provider.dart';
import 'location_provider.dart';

part 'app_providers.g.dart';

@riverpod
LocalStorageService localStorage(LocalStorageRef ref) {
  return LocalStorageService();
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
PropertyService propertyService(PropertyServiceRef ref) {
  return PropertyService(
    getCity: () {
      final loc = ref.read(locationProvider).currentLabel;
      if (loc.isNotEmpty && loc != 'Unknown Location' && loc != 'Set location') {
        return loc.split(',').first.trim();
      }
      return null;
    },
  );
}

@riverpod
LeadService leadService(LeadServiceRef ref) {
  return LeadService();
}

@riverpod
FavoritesService favoritesService(FavoritesServiceRef ref) {
  return FavoritesService();
}

@riverpod
OwnerService ownerService(OwnerServiceRef ref) {
  return OwnerService();
}

@riverpod
GoogleGeocodingService googleGeocodingService(GoogleGeocodingServiceRef ref) {
  return GoogleGeocodingService(apiKey: "AIzaSyB9zroafCQGFNKoU1g5-ScptQBJo2FgpKw");
}

@riverpod
VideoCacheService videoCacheService(VideoCacheServiceRef ref) {
  return VideoCacheService();
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(localStorageProvider),
  );
}

@riverpod
PropertyRepository propertyRepository(PropertyRepositoryRef ref) {
  return PropertyRepository(ref.watch(propertyServiceProvider));
}

@riverpod
LeadRepository leadRepository(LeadRepositoryRef ref) {
  return LeadRepository(ref.watch(leadServiceProvider));
}

@riverpod
OwnerRepository ownerRepository(OwnerRepositoryRef ref) {
  return OwnerRepository(ref.watch(ownerServiceProvider));
}

@riverpod
Future<List<String>> propertyImages(PropertyImagesRef ref, String propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  final token = ref.watch(authProvider).user?.token;
  return repo.fetchPropertyImages(propertyId, token: token);
}
