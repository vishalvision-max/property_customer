import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/owner_profile.dart';
import '../data/repositories/owner_repository.dart';
import 'app_providers.dart';

class OwnerProfileState {
  final bool isLoading;
  final OwnerProfile? profile;
  final String? error;

  const OwnerProfileState({
    required this.isLoading,
    required this.profile,
    required this.error,
  });

  factory OwnerProfileState.initial() => const OwnerProfileState(
        isLoading: false,
        profile: null,
        error: null,
      );

  OwnerProfileState copyWith({
    bool? isLoading,
    Object? profile = _unset,
    String? error,
  }) {
    return OwnerProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile == _unset ? this.profile : profile as OwnerProfile?,
      error: error,
    );
  }

  static const Object _unset = Object();
}

class OwnerProfileNotifier extends StateNotifier<OwnerProfileState> {
  final OwnerRepository _repo;
  OwnerProfileNotifier(this._repo) : super(OwnerProfileState.initial());

  Future<void> load({required String token}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final p = await _repo.fetchProfile(token: token);
      state = state.copyWith(isLoading: false, profile: p, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<OwnerProfile?> update({
    required String token,
    required String name,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repo.updateProfile(token: token, name: name, imageFile: imageFile);
      // After edit, hit GET profile to ensure latest name/photo is reflected everywhere (drawer/profile).
      try {
        final fresh = await _repo.fetchProfile(token: token);
        state = state.copyWith(isLoading: false, profile: fresh, error: null);
        return fresh;
      } catch (_) {
        state = state.copyWith(isLoading: false, profile: updated, error: null);
        return updated;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final ownerProfileProvider = StateNotifierProvider<OwnerProfileNotifier, OwnerProfileState>(
  (ref) => OwnerProfileNotifier(ref.watch(ownerRepositoryProvider)),
);
