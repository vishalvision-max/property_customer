import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nav_provider.g.dart';

/// Holds the currently selected bottom-nav index.
/// Exposed so any widget deep in the tree can read or change the active tab
/// without needing a callback chain.
@riverpod
class Nav extends _$Nav {
  @override
  int build() => 0;

  void goTo(int index) {
    if (state != index) state = index;
  }
}
