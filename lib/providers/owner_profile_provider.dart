import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/owner_profile.dart';
import 'app_providers.dart';

part 'owner_profile_provider.freezed.dart';
part 'owner_profile_provider.g.dart';

@freezed
class OwnerProfileState with _$OwnerProfileState {
  const factory OwnerProfileState({
    required bool isLoading,
    required OwnerProfile? profile,
    required String? error,
  }) = _OwnerProfileState;

  factory OwnerProfileState.initial() => const OwnerProfileState(
        isLoading: false,
        profile: null,
        error: null,
      );
}

@riverpod
class OwnerProfileNotifier extends _$OwnerProfileNotifier {
  @override
  OwnerProfileState build() {
    return OwnerProfileState.initial();
  }

  Future<void> load({required String token}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final p = await repo.fetchProfile(token: token);
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
      final repo = ref.read(ownerRepositoryProvider);
      final updated = await repo.updateProfile(token: token, name: name, imageFile: imageFile);
      try {
        final fresh = await repo.fetchProfile(token: token);
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
