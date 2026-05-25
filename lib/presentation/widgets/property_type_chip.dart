import 'package:flutter/material.dart';

class PropertyTypeChip extends StatelessWidget {
  final String type;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const PropertyTypeChip({
    super.key,
    required this.type,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  bool get _isRent => type.toLowerCase() == 'rent';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = (_isRent ? cs.primaryContainer : cs.tertiaryContainer)
        .withValues(alpha: 0.9);
    final fg = _isRent ? cs.onPrimaryContainer : cs.onTertiaryContainer;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 1),
            blurRadius: 1,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _isRent ? 'Rent' : 'Sale',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

