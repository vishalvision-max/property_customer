import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/lead.dart';

class LeadService {
  static final Uri _baseUri = Uri.parse(
    'https://propertysearch.visionvivante.in',
  );

  Future<LeadPage> fetchMyLeads({required String token, int page = 1}) async {
    if (kIsWeb) {
      throw Exception('Leads API is not supported on web in this build');
    }
    final uri = _baseUri.replace(
      path: '/api/v1/own-leads',
      queryParameters: <String, String>{'page': page.toString()},
    );

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final status = res.statusCode;

      if (status < 200 || status >= 300) {
        throw Exception('Failed to load leads ($status)');
      }

      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return LeadPage.fromJson(decoded);
      }
      throw Exception('Leads response was unexpected');
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> updateLeadStatus({
    required String token,
    required String leadId,
    required String status,
  }) async {
    if (kIsWeb) {
      throw Exception('Leads API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/leads/$leadId/status');

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer $token');
      req.write(jsonEncode(<String, dynamic>{'status': status}));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final code = res.statusCode;
      if (code < 200 || code >= 300) {
        final msg = _extractError(body) ?? 'Failed to update lead ($code)';
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> createLead({
    String? token,
    required String name,
    required String phone,
    String? email,
    required String type,
    required String propertyType,
    required String city,
    required String state,
    required String pincode,
    String? address,
    String? budgetMin,
    String? budgetMax,
    String? message,
    String? source,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
  }) async {
    if (kIsWeb) {
      throw Exception('Leads API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/leads');

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.set('Accept', 'application/json');
      if (token != null && token.trim().isNotEmpty) {
        req.headers.set('Authorization', 'Bearer ${token.trim()}');
      }

      req.write(
        jsonEncode(<String, dynamic>{
          'name': name,
          'email': email,
          'phone': phone,
          'type': type,
          'property_type': propertyType,
          'city': city,
          'state': state,
          'pincode': pincode,
          'address': address,
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'message': message,
          'source': source,
          'utm_source': utmSource,
          'utm_medium': utmMedium,
          'utm_campaign': utmCampaign,
        }),
      );

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final code = res.statusCode;
      if (code < 200 || code >= 300) {
        final msg = _extractError(body) ?? 'Failed to submit lead ($code)';
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> createBuyerLead({
    required String token,
    required String name,
    required String phone,
    required String email,
    required String message,
    required String type,
    required int propertyId,
  }) async {
    if (kIsWeb) {
      throw Exception('Leads API is not supported on web in this build');
    }
    final uri = _baseUri.replace(path: '/api/v1/save-buyer-leads');

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.set('Accept', 'application/json');
      req.headers.set('Authorization', 'Bearer ${token.trim()}');

      req.write(
        jsonEncode(<String, dynamic>{
          'name': name,
          'phone': phone,
          'email': email,
          'message': message,
          'type': type,
          'lead_types': 'buyer',
          'property_id': propertyId,
        }),
      );

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final code = res.statusCode;
      if (code < 200 || code >= 300) {
        final msg = _extractError(body) ?? 'Failed to submit buyer lead ($code)';
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } finally {
      client.close(force: true);
    }
  }

  String? _extractError(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final direct = decoded['message'] ?? decoded['error'];
        if (direct is String && direct.trim().isNotEmpty) return direct.trim();
        final errors = decoded['errors'];
        if (errors is Map) {
          for (final v in errors.values) {
            if (v is List && v.isNotEmpty) return v.first.toString();
            if (v is String && v.trim().isNotEmpty) return v.trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
