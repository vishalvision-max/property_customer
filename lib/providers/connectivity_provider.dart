import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<ConnectivityResult> connectivity(ConnectivityRef ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((list) => list.isEmpty ? ConnectivityResult.none : list.first);
}
