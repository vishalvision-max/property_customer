// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$navHash() => r'52ca59d78625626f52bf119ccbd6ba4433bbdd31';

/// Holds the currently selected bottom-nav index.
/// Exposed so any widget deep in the tree can read or change the active tab
/// without needing a callback chain.
///
/// Copied from [Nav].
@ProviderFor(Nav)
final navProvider = AutoDisposeNotifierProvider<Nav, int>.internal(
  Nav.new,
  name: r'navProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$navHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Nav = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
