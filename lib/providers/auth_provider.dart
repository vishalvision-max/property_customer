import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import 'app_providers.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final String? message;
  final bool seenOnboarding;

  static const Object _unset = Object();

  const AuthState({
    required this.isLoading,
    required this.user,
    required this.error,
    required this.message,
    required this.seenOnboarding,
  });

  // Start in a loading state so the router keeps the user on `/splash` until
  // `bootstrap()` loads cached session/onboarding flags.
  factory AuthState.initial() => const AuthState(
    isLoading: true,
    user: null,
    error: null,
    message: null,
    seenOnboarding: false,
  );

  AuthState copyWith({
    bool? isLoading,
    Object? user = _unset,
    String? error,
    String? message,
    bool? seenOnboarding,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user == _unset ? this.user : user as User?,
      error: error,
      message: message,
      seenOnboarding: seenOnboarding ?? this.seenOnboarding,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;
  AuthNotifier(this._repo, this._ref) : super(AuthState.initial());

  static const _kOnboarding = 'seen_onboarding';

  Future<AuthState> bootstrap() async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final user = await _repo.getCachedUser();
      final sp = await _ref.read(_sharedPrefsProvider.future);
      final seen = sp.getBool(_kOnboarding) ?? false;
      state = state.copyWith(isLoading: false, user: user, seenOnboarding: seen, error: null, message: null);
      return state;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
      return state;
    }
  }

  Future<void> setSeenOnboarding() async {
    final sp = await _ref.read(_sharedPrefsProvider.future);
    await sp.setBool(_kOnboarding, true);
    state = state.copyWith(seenOnboarding: true);
  }

  Future<void> login({required String email, required String password}) async {
    // Treat an explicit login attempt as a new session.
    // This prevents stale cached `user` state from causing router redirects
    // when the login request fails (e.g. 401/500).
    state = state.copyWith(isLoading: true, error: null, message: null, user: null);
    try {
      final user = await _repo.login(email: email, password: password);
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
      final user = await _repo.signup(
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
      final msg = await _repo.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, error: null, message: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), message: null);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref),
);

// SharedPreferences is used in a small, isolated provider so tests/mocks can override it later.
final _sharedPrefsProvider = FutureProvider((ref) async {
  return await SharedPreferences.getInstance();
});
