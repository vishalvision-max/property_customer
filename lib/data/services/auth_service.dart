import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class AuthService {
  static final Uri _baseUri = Uri.parse('https://propertysearch.visionvivante.in');

  Future<User> login({required String email, required String password}) async {
    if (kIsWeb) {
      throw Exception('Login API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/v1/login');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode(<String, dynamic>{
          'email': email,
          'password': password,
        }),
      );

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Login failed ($status)';
        throw Exception(msg);
      }

      final userJson = (json?['user'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final user = User.fromJson(userJson);
      final token = (json?['token'] ?? user.token).toString();

      if (user.id.isEmpty || user.email.isEmpty || token.isEmpty) {
        throw Exception('Login succeeded but response was unexpected');
      }

      // Save token into the User model so LocalStorageService can persist it.
      return User(id: user.id, name: user.name, email: user.email, token: token);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<User> signup({required String name, required String email, required String password}) async {
    if (kIsWeb) {
      throw Exception('Signup API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/register');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode(<String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Signup failed ($status)';
        throw Exception(msg);
      }

      final userJson =
          (json?['user'] as Map?)?.cast<String, dynamic>() ??
          (json?['data'] as Map?)?.cast<String, dynamic>() ??
          json;

      final user = User.fromJson(userJson ?? const <String, dynamic>{});
      final token = (json?['token'] ?? user.token).toString();

      if (user.id.isEmpty || user.email.isEmpty || token.isEmpty) {
        throw Exception('Signup succeeded but response was unexpected');
      }

      return User(id: user.id, name: user.name, email: user.email, token: token);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> forgotPassword({required String email}) async {
    if (kIsWeb) {
      throw Exception('Forgot password API is not supported on web in this build');
    }

    final uri = _baseUri.replace(path: '/api/v1/forget/password');
    try {
      final req = http.MultipartRequest('POST', uri);
      req.headers['accept'] = 'application/json';
      req.fields['email'] = email;

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final status = streamed.statusCode;

      Map<String, dynamic>? json;
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (status < 200 || status >= 300) {
        final msg = _extractError(json) ?? 'Request failed ($status)';
        throw Exception(msg);
      }

      final message = (json?['message'] ?? '').toString().trim();
      return message.isNotEmpty ? message : 'Reset link sent successfully';
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
