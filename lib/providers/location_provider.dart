import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/saved_address.dart';
import 'app_providers.dart';

part 'location_provider.freezed.dart';
part 'location_provider.g.dart';

@freezed
class LocationState with _$LocationState {
  const factory LocationState({
    required bool isLoading,
    required String currentLabel,
    required double? lat,
    required double? lng,
    required List<SavedAddress> saved,
    required String? error,
  }) = _LocationState;

  factory LocationState.initial() => const LocationState(
    isLoading: false,
    currentLabel: 'Set location',
    lat: null,
    lng: null,
    saved: [],
    error: null,
  );
}

@riverpod
class Location extends _$Location {
  @override
  LocationState build() {
    return LocationState.initial();
  }

  /// Adds/updates [addr] in the saved list (matched by label) and persists.
  List<SavedAddress> _upsert(SavedAddress addr) {
    final next = state.saved.where((a) => a.label != addr.label).toList()
      ..add(addr);
    return next;
  }

  Future<void> load() async {
    final storage = ref.read(localStorageProvider);
    final saved = await storage.getLocations();
    final preferred = await storage.getPreferredLocation();
    state = state.copyWith(
      saved: saved,
      currentLabel: preferred ?? state.currentLabel,
    );
  }

  /// Called when the user submits raw typed text without picking an
  /// autocomplete suggestion. Forward-geocodes it so the saved entry still
  /// gets real coordinates where possible.
  Future<void> setManual(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;

    final googleGeocoding = ref.read(googleGeocodingServiceProvider);
    final resolved = await googleGeocoding.geocodeAddress(v);

    final addr = SavedAddress(
      label: v,
      lat: resolved?.lat ?? state.lat ?? 0.0,
      lng: resolved?.lng ?? state.lng ?? 0.0,
    );
    final nextSaved = _upsert(addr);
    state = state.copyWith(
      currentLabel: v,
      lat: addr.lat,
      lng: addr.lng,
      saved: nextSaved,
      error: null,
    );
    final storage = ref.read(localStorageProvider);
    await storage.setPreferredLocation(v);
    await storage.saveLocations(nextSaved);
  }

  /// Called when the user picked an autocomplete suggestion (has a real
  /// place_id) or confirmed a pin dropped on the map — coordinates are exact.
  Future<void> setPickedLocation(String label, double lat, double lng) async {
    final v = label.trim();
    if (v.isEmpty) return;
    final addr = SavedAddress(label: v, lat: lat, lng: lng);
    final nextSaved = _upsert(addr);
    state = state.copyWith(
      currentLabel: v,
      lat: lat,
      lng: lng,
      saved: nextSaved,
      error: null,
    );
    final storage = ref.read(localStorageProvider);
    await storage.setPreferredLocation(v);
    await storage.saveLocations(nextSaved);
  }

  /// Re-selects a previously saved address as the current location.
  Future<void> selectSaved(SavedAddress addr) async {
    state = state.copyWith(
      currentLabel: addr.label,
      lat: addr.lat,
      lng: addr.lng,
      error: null,
    );
    final storage = ref.read(localStorageProvider);
    await storage.setPreferredLocation(addr.label);
  }

  Future<void> removeSaved(String label) async {
    final nextSaved = state.saved.where((a) => a.label != label).toList();
    state = state.copyWith(saved: nextSaved);
    final storage = ref.read(localStorageProvider);
    await storage.saveLocations(nextSaved);
  }

  Future<void> fetchCurrent() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location services are disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final googleGeocoding = ref.read(googleGeocodingServiceProvider);
      String? label = await googleGeocoding.reverseGeocode(
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (label == null || label.trim().isEmpty) {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        final place = placemarks.isEmpty ? null : placemarks.first;
        label = [
          place?.locality,
          place?.administrativeArea,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');
      }
      if (label.trim().isEmpty) throw Exception('Unable to resolve location');

      final addr = SavedAddress(
        label: label,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      final nextSaved = _upsert(addr);
      state = state.copyWith(
        isLoading: false,
        currentLabel: label,
        lat: pos.latitude,
        lng: pos.longitude,
        saved: nextSaved,
        error: null,
      );
      final storage = ref.read(localStorageProvider);
      await storage.setPreferredLocation(label);
      await storage.saveLocations(nextSaved);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
