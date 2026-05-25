import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/property.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import 'autoplay_video_preview.dart';
import 'property_type_chip.dart';

class PropertyCard extends ConsumerWidget {
  final Property property;
  final VoidCallback onTap;
  final Color? amenityIconColor;
  final bool compact;
  final bool enableVideoPreview;
  final bool videoLoop;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.amenityIconColor,
    this.compact = false,
    this.enableVideoPreview = true,
    this.videoLoop = true,
  });

  static const _fallbackPropertyImage =
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthed = ref.watch(authProvider).user != null;
    final isFav = ref.watch(
      favoritesProvider.select((s) => s.contains(property.id)),
    );
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overrideAmenityIconColor = amenityIconColor;

    final imageH = compact ? 170.0 : 255.0;
    final contentH = compact ? 140.0 : 160.0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF0F1A2D) : Colors.white,
          boxShadow: [AppTheme.softShadow(context)],
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.45),
          ),
        ),
        child: Row(
          children: [
            // SizedBox(width: 5),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 120,
                height: imageH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (enableVideoPreview && property.videos.isNotEmpty)
                      AutoplayVideoPreview(
                        url: property.videos.first.trim(),
                        loop: videoLoop,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                        loading: Container(color: cs.surfaceContainerHighest),
                        error: CachedNetworkImage(
                          imageUrl: property.images.isEmpty
                              ? _fallbackPropertyImage
                              : property.images.first.trim(),
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (property.images.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: property.images.first.trim(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: cs.surfaceContainerHighest),
                        errorWidget: (context, url, error) => Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.photo, size: 30),
                        ),
                      )
                    else
                      // Images not bundled in list response — lazy-load from details
                      _LazyPropertyImage(
                        propertyId: property.id,
                        fallback: _fallbackPropertyImage,
                      ),
                    if (enableVideoPreview && property.videos.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: SizedBox(
                  height: contentH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (!isAuthed) {
                                AppSnackbar.showError(
                                  context,
                                  'Please login to add favorites',
                                );
                                context.push(
                                  '/login?from=${Uri.encodeComponent('/property/${property.id}')}',
                                );
                                return;
                              }
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggleRemote(
                                    type: 'property',
                                    id: property.id,
                                  )
                                  .catchError((_) {
                                    if (!context.mounted) return;
                                    AppSnackbar.showError(
                                      context,
                                      'Failed to update wishlist. Please try again.',
                                    );
                                  });
                            },
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? Colors.pinkAccent
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          PropertyTypeChip(type: property.type),
                          const SizedBox(width: 10),
                          for (final a in property.amenities.take(4))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                _amenityIcon(a),
                                size: 18,
                                color:
                                    overrideAmenityIconColor ??
                                    _amenityIconColor(a),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(property),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(Property p) =>
      p.type == 'rent' ? '\$${p.price}/mo' : '\$${p.price.toString()}';

  static IconData _amenityIcon(String a) {
    switch (a) {
      case 'Water':
        return Icons.water_drop;
      case 'Electricity':
        return Icons.bolt_outlined;
      case 'Parking':
        return Icons.local_parking_outlined;
      case 'Security':
        return Icons.shield;
      default:
        return Icons.check_circle_outline;
    }
  }

  static Color _amenityIconColor(String a) {
    switch (a) {
      case 'Water':
        return Colors.blue;
      case 'Electricity':
        return Colors.yellow.shade700;
      case 'Parking':
        return Colors.red;
      case 'Security':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}

/// Lazy-loads the first image for a property when the list endpoint
/// doesn't include images. Uses [propertyImagesProvider] which caches
/// the result so each property is only fetched once.
class _LazyPropertyImage extends ConsumerWidget {
  final String propertyId;
  final String fallback;

  const _LazyPropertyImage({required this.propertyId, required this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(propertyImagesProvider(propertyId));

    return async.when(
      loading: () => Container(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      error: (_, __) => CachedNetworkImage(
        imageUrl: fallback,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(color: cs.surfaceContainerHighest),
        errorWidget: (context, url, error) => Container(
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.photo, size: 30),
        ),
      ),
      data: (images) => CachedNetworkImage(
        imageUrl: images.isNotEmpty ? images.first : fallback,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(color: cs.surfaceContainerHighest),
        errorWidget: (context, url, error) =>
            CachedNetworkImage(imageUrl: fallback, fit: BoxFit.cover),
      ),
    );
  }
}
