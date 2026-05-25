import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/services/google_geocoding_service.dart';
import '../data/services/local_storage_service.dart';
import 'app_providers.dart';

class LocationState {
  final bool isLoading;
  final String currentLabel;
  final double? lat;
  final double? lng;
  final List<String> saved;
  final String? error;

  const LocationState({
    required this.isLoading,
    required this.currentLabel,
    required this.lat,
    required this.lng,
    required this.saved,
    required this.error,
  });

  factory LocationState.initial() => const LocationState(
        isLoading: false,
        currentLabel: 'Set location',
        lat: null,
        lng: null,
        saved: [],
        error: null,
      );

  LocationState copyWith({
    bool? isLoading,
    String? currentLabel,
    double? lat,
    double? lng,
    List<String>? saved,
    String? error,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      currentLabel: currentLabel ?? this.currentLabel,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      saved: saved ?? this.saved,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocalStorageService _storage;
  final GoogleGeocodingService _googleGeocoding;
  LocationNotifier(this._storage, this._googleGeocoding)
      : super(LocationState.initial());

  Future<void> load() async {
    final saved = await _storage.getLocations();
    final preferred = await _storage.getPreferredLocation();
    state = state.copyWith(saved: saved, currentLabel: preferred ?? state.currentLabel);
  }

  Future<void> setManual(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    final nextSaved = {...state.saved};
    nextSaved.add(v);
    state = state.copyWith(currentLabel: v, saved: nextSaved.toList(), error: null);
    await _storage.setPreferredLocation(v);
    await _storage.saveLocations(nextSaved.toList());
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

      String? label = await _googleGeocoding.reverseGeocode(
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
      await _storage.setPreferredLocation(label);
      await _storage.saveLocations(nextSaved.toList());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(
    ref.watch(localStorageProvider),
    ref.watch(googleGeocodingServiceProvider),
  ),
);
