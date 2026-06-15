import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/owner_profile.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

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
    required String email,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final updated = await repo.updateProfile(token: token, name: name, email: email, imageFile: imageFile);
      OwnerProfile finalProfile;
      if (updated.name.trim().isNotEmpty && updated.email.trim().isNotEmpty) {
        finalProfile = updated;
      } else if (state.profile != null) {
        finalProfile = OwnerProfile(
          id: state.profile!.id,
          name: name.trim(),
          email: email.trim(),
          phone: state.profile!.phone,
          imageUrl: updated.imageUrl.isNotEmpty ? updated.imageUrl : state.profile!.imageUrl,
        );
      } else {
        finalProfile = OwnerProfile(
          id: '',
          name: name.trim(),
          email: email.trim(),
          phone: '',
          imageUrl: updated.imageUrl,
        );
      }

      state = state.copyWith(isLoading: false, profile: finalProfile, error: null);
      ref.read(authProvider.notifier).syncProfileUpdate(name: finalProfile.name, email: finalProfile.email);
      return finalProfile;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
