import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: AppTheme.glassBlur(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF101A2E) : Colors.white).withValues(alpha: isDark ? 0.55 : 0.65),
            borderRadius: borderRadius,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45)),
            boxShadow: [AppTheme.softShadow(context)],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
