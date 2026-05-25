import 'package:flutter/material.dart';

/// Wraps a child widget with [AutomaticKeepAliveClientMixin] so that
/// PageView does not destroy the page when it scrolls out of view.
/// This is the standard Flutter pattern for preserving tab state.
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by the mixin
    return widget.child;
  }
}
