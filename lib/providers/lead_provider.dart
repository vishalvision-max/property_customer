import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/lead.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

part 'lead_provider.freezed.dart';
part 'lead_provider.g.dart';

@freezed
class LeadState with _$LeadState {
  const factory LeadState({
    required bool isLoading,
    required List<Lead> items,
    required int currentPage,
    required int lastPage,
    required int total,
    required String? error,
  }) = _LeadState;

  factory LeadState.initial() => const LeadState(
        isLoading: false,
        items: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
        error: null,
      );
}

@riverpod
class LeadNotifier extends _$LeadNotifier {
  @override
  LeadState build() {
    return LeadState.initial();
  }

  String? _tokenOrNull() => ref.read(authProvider).user?.token;

  Future<bool> _maybeLogoutOnUnauthorized(Object e) async {
    final msg = e.toString();
    final unauthorized =
        msg.contains('(401)') ||
        msg.contains(' 401') ||
        msg.contains('401 ');
    if (!unauthorized) return false;
    await ref.read(authProvider.notifier).logout();
    state = state.copyWith(
      isLoading: false,
      error: 'Session expired. Please login again.',
    );
    return true;
  }

  Future<void> loadMyLeads({int page = 1}) async {
    final token = _tokenOrNull();
    if (token == null || token.trim().isEmpty) {
      state = state.copyWith(error: 'Please login to view your leads');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(leadRepositoryProvider);
      final res = await repo.fetchMyLeads(token: token.trim(), page: page);
      state = state.copyWith(
        isLoading: false,
        items: res.data,
        currentPage: res.currentPage,
        lastPage: res.lastPage,
        total: res.total,
        error: null,
      );
    } catch (e) {
      if (await _maybeLogoutOnUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus({
    required String leadId,
    required String status,
  }) async {
    final token = _tokenOrNull();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Please login to update lead status');
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(leadRepositoryProvider);
      await repo.updateStatus(
        token: token.trim(),
        leadId: leadId,
        status: status,
      );
      await loadMyLeads(page: state.currentPage);
    } catch (e) {
      if (await _maybeLogoutOnUnauthorized(e)) rethrow;
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createLead({
    required String name,
    required String phone,
    String? email,
    required String type,
    required String propertyType,
    required String city,
    required String stateName,
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
    final token = _tokenOrNull();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Please login to submit a lead');
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(leadRepositoryProvider);
      await repo.create(
        token: token.trim(),
        name: name,
        phone: phone,
        email: email,
        type: type,
        propertyType: propertyType,
        city: city,
        state: stateName,
        pincode: pincode,
        address: address,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        message: message,
        source: source,
        utmSource: utmSource,
        utmMedium: utmMedium,
        utmCampaign: utmCampaign,
      );
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      if (await _maybeLogoutOnUnauthorized(e)) rethrow;
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createBuyerLead({
    required String name,
    required String phone,
    required String email,
    required String message,
    required String type,
    required int propertyId,
  }) async {
    final token = _tokenOrNull();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Please login to submit a lead');
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(leadRepositoryProvider);
      await repo.createBuyerLead(
        token: token.trim(),
        name: name,
        phone: phone,
        email: email,
        message: message,
        type: type,
        propertyId: propertyId,
      );
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      if (await _maybeLogoutOnUnauthorized(e)) rethrow;
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
