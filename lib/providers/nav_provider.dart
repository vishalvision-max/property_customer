import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected bottom-nav index.
/// Exposed so any widget deep in the tree can read or change the active tab
/// without needing a callback chain.
class NavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) {
    if (state != index) state = index;
  }
}

final navProvider = NotifierProvider<NavNotifier, int>(NavNotifier.new);
