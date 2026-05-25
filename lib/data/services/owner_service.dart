import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/owner_profile.dart';

class OwnerService {
  static final Uri _baseUri = Uri.parse(
    'https://propertysearch.visionvivante.in',
  );

  Future<OwnerProfile> fetchProfile({required String token}) async {
    if (kIsWeb) {
      throw Exception(
        'Owner profile API is not supported on web in this build',
      );
    }
    final uri = _baseUri.replace(path: '/api/v1/owner/profile');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('accept', 'application/json');
      req.headers.set('authorization', 'Bearer ${token.trim()}');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Failed to load profile ($status)';
        throw Exception(msg);
      }

      final data =
          (json?['data'] as Map?)?.cast<String, dynamic>() ??
          (json?['owner'] as Map?)?.cast<String, dynamic>() ??
          (json?['profile'] as Map?)?.cast<String, dynamic>() ??
          json ??
          const <String, dynamic>{};

      return OwnerProfile.fromJson(data);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<OwnerProfile> updateProfile({
    required String token,
    required String name,
    File? imageFile,
  }) async {
    if (kIsWeb) {
      throw Exception(
        'Owner edit profile API is not supported on web in this build',
      );
    }
    final uri = _baseUri.replace(path: '/api/v1/owner/edit/profile');
    try {
      final req = http.MultipartRequest('POST', uri);
      req.headers['accept'] = 'application/json';
      req.headers['authorization'] = 'Bearer ${token.trim()}';
      req.fields['name'] = name.trim();

      if (imageFile != null) {
        final file = await http.MultipartFile.fromPath('image', imageFile.path);
        req.files.add(file);
      }

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final status = streamed.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Update profile failed ($status)';
        throw Exception(msg);
      }

      final data =
          (json?['data'] as Map?)?.cast<String, dynamic>() ??
          (json?['owner'] as Map?)?.cast<String, dynamic>() ??
          (json?['profile'] as Map?)?.cast<String, dynamic>() ??
          json ??
          const <String, dynamic>{};

      return OwnerProfile.fromJson(data);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  Future<String> updatePassword({
    required String token,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (kIsWeb) {
      throw Exception(
        'Owner password API is not supported on web in this build',
      );
    }
    final uri = _baseUri.replace(path: '/api/v1/owner/password/update');
    try {
      final req = http.MultipartRequest('POST', uri);
      req.headers['accept'] = 'application/json';
      req.headers['authorization'] = 'Bearer ${token.trim()}';
      req.fields['current_password'] = currentPassword;
      req.fields['password'] = password;
      req.fields['password_confirmation'] = passwordConfirmation;

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final status = streamed.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Update password failed ($status)';
        throw Exception(msg);
      }

      final message = (json?['message'] ?? 'Password updated successfully')
          .toString()
          .trim();
      return message.isEmpty ? 'Password updated successfully' : message;
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  String? _extractError(Map<String, dynamic>? json) {
    if (json == null) return null;
    final direct = json['message'] ?? json['error'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    final errors = json['errors'];
    if (errors is Map) {
      for (final v in errors.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }
}
