import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_address.dart';
import '../models/user.dart';

class LocalStorageService {
  static const _kUser = 'user';
  static const _kUserId = 'user_id';
  static const _kToken = 'token';
  static const _kFavorites = 'favorites';
  static const _kSavedLocations = 'saved_locations';
  static const _kPreferredLocation = 'preferred_location';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kToken, user.token);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final user = User.fromJson(map);
    if (user.token.trim().isEmpty) return null;
    return user;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await prefs.remove(_kUserId);
    await prefs.remove(_kToken);
  }

  Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, ids.toList());
  }

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kFavorites) ?? const <String>[]).toSet();
  }

  Future<void> saveLocations(List<SavedAddress> locations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kSavedLocations,
      locations.map((l) => jsonEncode(l.toJson())).toList(),
    );
  }

  Future<List<SavedAddress>> getLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedLocations) ?? const <String>[];
    final result = <SavedAddress>[];
    for (final entry in raw) {
      try {
        result.add(
          SavedAddress.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        // Ignore entries saved in the old plain-string format.
      }
    }
    return result;
  }

  Future<void> setPreferredLocation(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredLocation, value);
  }

  Future<String?> getPreferredLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPreferredLocation);
  }
}
