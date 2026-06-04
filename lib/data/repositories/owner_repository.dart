import 'dart:io';

import '../models/owner_profile.dart';
import '../services/owner_service.dart';

class OwnerRepository {
  final OwnerService _service;
  OwnerRepository(this._service);

  Future<OwnerProfile> fetchProfile({required String token}) {
    return _service.fetchProfile(token: token);
  }

  Future<OwnerProfile> updateProfile({
    required String token,
    required String name,
    required String email,
    File? imageFile,
  }) {
    return _service.updateProfile(token: token, name: name, email: email, imageFile: imageFile);
  }

  Future<String> updatePassword({
    required String token,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _service.updatePassword(
      token: token,
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
