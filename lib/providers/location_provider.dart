import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    required List<String> saved,
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

  Future<void> load() async {
    final storage = ref.read(localStorageProvider);
    final saved = await storage.getLocations();
    final preferred = await storage.getPreferredLocation();
    state = state.copyWith(saved: saved, currentLabel: preferred ?? state.currentLabel);
  }

  Future<void> setManual(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    final nextSaved = {...state.saved};
    nextSaved.add(v);
    state = state.copyWith(currentLabel: v, saved: nextSaved.toList(), error: null);
    final storage = ref.read(localStorageProvider);
    await storage.setPreferredLocation(v);
    await storage.saveLocations(nextSaved.toList());
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final googleGeocoding = ref.read(googleGeocodingServiceProvider);
      String? label = await googleGeocoding.reverseGeocode(
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (label == null || label.trim().isEmpty) {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        final place = placemarks.isEmpty ? null : placemarks.first;
        label = [
          place?.locality,
          place?.administrativeArea,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');
      }
      if (label.trim().isEmpty) throw Exception('Unable to resolve location');

      final nextSaved = {...state.saved}..add(label);
      state = state.copyWith(
        isLoading: false,
        currentLabel: label,
        lat: pos.latitude,
        lng: pos.longitude,
        saved: nextSaved.toList(),
        error: null,
      );
      final storage = ref.read(localStorageProvider);
      await storage.setPreferredLocation(label);
      await storage.saveLocations(nextSaved.toList());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
