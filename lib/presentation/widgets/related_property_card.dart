import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class RelatedPropertyCard extends ConsumerWidget {
  final Property property;
  final VoidCallback onTap;

  const RelatedPropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
  }) : super(key: key);

  String _formatIndianPrice(int price, String type) {
    if (type == 'rent') {
      if (price >= 100000) {
        double lakhs = price / 100000.0;
        return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} L/mo';
      }
      String priceStr = price.toString();
      if (priceStr.length > 3) {
        priceStr = priceStr.replaceAllMapped(
          RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
      return '₹$priceStr /mo';
    } else {
      if (price >= 10000000) {
        double crores = price / 10000000.0;
        return '₹${crores.toStringAsFixed(crores % 1 == 0 ? 0 : 2)} Cr';
      } else if (price >= 100000) {
        double lakhs = price / 100000.0;
        return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh';
      }
      return '₹$price';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthed = ref.watch(authProvider).user != null;
    final isFav = ref.watch(
      favoritesProvider.select((s) => s.contains(property.id)),
    );

    final displayPrice = _formatIndianPrice(property.price, property.type);
    
    // Determine Type string (simplified)
    String typeStr = 'Property';
    if (property.categoryName != null && property.categoryName!.isNotEmpty) {
      typeStr = property.categoryName!;
    } else if (property.name.toLowerCase().contains('apartment')) {
      typeStr = 'Apartment';
    } else if (property.name.toLowerCase().contains('villa')) {
      typeStr = 'Villa';
    }

    String _getSectorAndState(String fullLocation) {
      final loc = fullLocation.trim();
      if (loc.isEmpty) return 'Panchkula';
      final parts = loc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      if (parts.isNotEmpty && parts.last.toLowerCase() == 'india') {
        parts.removeLast();
      }

      if (parts.isNotEmpty) {
        final cleanState = parts.last.replaceAll(RegExp(r'\d+'), '').trim();
        if (cleanState.isNotEmpty) {
          parts[parts.length - 1] = cleanState;
        } else {
          parts.removeLast();
        }
      }

      if (parts.isNotEmpty) {
        final first = parts.first;
        final isFlatNo = RegExp(
          r'^(\d+|\w-\d+|\d+\w|\bflat\b|\broom\b|\bshop\b|\bfloor\b|\bplot\b)',
          caseSensitive: false,
        ).hasMatch(first);
        if (isFlatNo || first.length <= 5) {
          parts.removeAt(0);
        }
      }

      if (parts.isEmpty) return 'Panchkula';
      
      if (parts.length >= 2) {
        // Return Locality/Sector and State
        return '${parts.first}, ${parts.last}';
      }
      return parts.first;
    }

    final subAddress = _getSectorAndState(property.location);

    String imageUrl = 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';
    if (property.images.isNotEmpty) {
      imageUrl = property.images.first;
    } else {
      final asyncImages = ref.watch(propertyImagesProvider(property.id));
      if (asyncImages.hasValue && asyncImages.value!.isNotEmpty) {
        imageUrl = asyncImages.value!.first;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFFF2F4F7)),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF2F4F7),
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (!isAuthed) {
                          AppSnackbar.showError(context, 'Please login to add favorites');
                          context.push('/login?from=${Uri.encodeComponent('/property/${property.id}')}');
                          return;
                        }
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleRemote(type: 'property', id: property.id)
                            .catchError((_) {
                          if (!context.mounted) return;
                          AppSnackbar.showError(context, 'Failed to update wishlist. Please try again.');
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFD92D20) : const Color(0xFF475467),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property.type.toLowerCase() == 'sale' ? 'FOR SALE' : 'FOR RENT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    typeStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF98A2B3)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
