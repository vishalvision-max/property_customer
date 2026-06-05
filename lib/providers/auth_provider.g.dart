// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPrefsHash() => r'f8917d2fd067cfa6a1a8c5fb4faf6e72fa1506a1';

/// See also [sharedPrefs].
@ProviderFor(sharedPrefs)
final sharedPrefsProvider =
    AutoDisposeFutureProvider<SharedPreferences>.internal(
      sharedPrefs,
      name: r'sharedPrefsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sharedPrefsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPrefsRef = AutoDisposeFutureProviderRef<SharedPreferences>;
String _$authHash() => r'bfa89409ae99f767d07b1f9a81af9ba82a3ed6f1';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider = AutoDisposeNotifierProvider<Auth, AuthState>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
