import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import 'app_providers.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required bool isLoading,
    required User? user,
    required String? error,
    required String? message,
    required bool seenOnboarding,
  }) = _AuthState;

  factory AuthState.initial() => const AuthState(
        isLoading: true,
        user: null,
        error: null,
        message: null,
        seenOnboarding: false,
      );
}

@riverpod
class Auth extends _$Auth {
  static const _kOnboarding = 'seen_onboarding';

  @override
  AuthState build() {
    return AuthState.initial();
  }

  Future<AuthState> bootstrap() async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getCachedUser();
      final sp = await ref.read(sharedPrefsProvider.future);
      final seen = sp.getBool(_kOnboarding) ?? false;
      state = state.copyWith(
        isLoading: false,
        user: user,
        seenOnboarding: seen,
        error: null,
        message: null,
      );
      return state;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
      return state;
    }
  }

  Future<void> setSeenOnboarding() async {
    final sp = await ref.read(sharedPrefsProvider.future);
    await sp.setBool(_kOnboarding, true);
    state = state.copyWith(seenOnboarding: true);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null, message: null, user: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email: email, password: password);
      state = state.copyWith(isLoading: false, user: user, error: null, message: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null, user: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signup(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(isLoading: false, user: user, error: null, message: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = await repo.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, error: null, message: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = state.copyWith(user: null);
  }
}

@riverpod
Future<SharedPreferences> sharedPrefs(SharedPrefsRef ref) async {
  return await SharedPreferences.getInstance();
}
