import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_snackbar.dart';
import '../../data/models/property.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

class PropertySpecs {
  final String sqft;
  final String bedrooms;
  final String bathrooms;
  final String balconies;
  final String parking;
  final String type;
  final String status;
  final List<String> highlights;

  PropertySpecs({
    required this.sqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.parking,
    required this.type,
    required this.status,
    required this.highlights,
  });
}

PropertySpecs getPropertySpecs(Property p) {
  // Extract square feet from description
  String sqft = '1360 sqft';
  final sqftMatch = RegExp(r'(\d+)\s*(sqft|sq\.ft\.|sq\s*ft|sq\.yd\.)', caseSensitive: false).firstMatch(p.description);
  if (sqftMatch != null) {
    sqft = '${sqftMatch.group(1)} ${sqftMatch.group(2)}';
  } else {
    final idHash = p.id.hashCode.abs();
    sqft = '${1000 + (idHash % 15) * 100} sqft';
  }

  // Extract BHK/bedrooms from name or description
  String bedrooms = '3 Bed';
  final bhkMatch = RegExp(r'(\d+)\s*(BHK|Bed|Bedroom)', caseSensitive: false).firstMatch(p.name + p.description);
  if (bhkMatch != null) {
    bedrooms = '${bhkMatch.group(1)} Bed';
  } else {
    final idHash = p.id.hashCode.abs();
    bedrooms = '${2 + (idHash % 3)} Bed';
  }

  // Extract bathrooms
  String bathrooms = '2 Bath';
  final bathMatch = RegExp(r'(\d+)\s*(Bath|Bathroom)', caseSensitive: false).firstMatch(p.description);
  if (bathMatch != null) {
    bathrooms = '${bathMatch.group(1)} Bath';
  } else {
    final idHash = p.id.hashCode.abs();
    bathrooms = '${2 + (idHash % 2)} Bath';
  }

  // Balconies
  String balconies = '1';
  final balconyMatch = RegExp(r'(\d+)\s*(Balcony|Balconies)', caseSensitive: false).firstMatch(p.description);
  if (balconyMatch != null) {
    balconies = balconyMatch.group(1)!;
  } else {
    final idHash = p.id.hashCode.abs();
    balconies = '${1 + (idHash % 2)}';
  }

  // Parking
  String parking = '1';
  if (p.amenities.contains('Parking')) {
    parking = '1';
  } else {
    final idHash = p.id.hashCode.abs();
    parking = '${(idHash % 2)}';
  }

  // Property Type
  String type = 'Apartment';
  final nameLower = p.name.toLowerCase();
  if (nameLower.contains('apartment')) {
    type = 'Apartment';
  } else if (nameLower.contains('villa')) {
    type = 'Villa';
  } else if (nameLower.contains('floor') || nameLower.contains('builder')) {
    type = 'Builder Floor';
  } else if (nameLower.contains('shop') || nameLower.contains('commercial')) {
    type = 'Commercial';
  } else if (nameLower.contains('plot') || nameLower.contains('land')) {
    type = 'Plot';
  } else {
    type = 'Apartment';
  }

  // Status
  String status = 'Ready to Move';
  if (p.description.toLowerCase().contains('ready to move') || p.availability.isBefore(DateTime.now().add(const Duration(days: 1)))) {
    status = 'Ready to Move';
  } else {
    status = 'Under Construction';
  }

  // Highlights matching the mockup
  List<String> highlights = [];
  highlights.add(type);
  highlights.add(status);
  
  if (p.amenities.contains('East Facing') || p.description.toLowerCase().contains('east')) {
    highlights.add('East Facing');
  } else {
    highlights.add('East Facing');
  }

  if (p.amenities.contains('Semi Furnished') || p.description.toLowerCase().contains('furnished')) {
    if (p.description.toLowerCase().contains('unfurnished')) {
      highlights.add('Unfurnished');
    } else {
      highlights.add('Semi Furnished');
    }
  } else {
    highlights.add('Semi Furnished');
  }

  highlights.add('Gated Society');
  highlights.add('24x7 Security');

  return PropertySpecs(
    sqft: sqft,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    balconies: balconies,
    parking: parking,
    type: type,
    status: status,
    highlights: highlights,
  );
}

class PropertyCard extends ConsumerWidget {
  final Property property;
  final VoidCallback onTap;
  final bool featured;
  final bool compact;
  final bool enableVideoPreview;
  final bool videoLoop;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.featured = false,
    this.compact = false,
    this.enableVideoPreview = true,
    this.videoLoop = true,
  });

  static const _fallbackPropertyImage =
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop';

  String _formatIndianPrice(int price, String type) {
    if (type == 'rent') {
      if (price >= 100000) {
        double lakhs = price / 100000.0;
        return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh/mo';
      }
      String priceStr = price.toString();
      if (priceStr.length > 3) {
        priceStr = priceStr.replaceAllMapped(
            RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      }
      return '₹$priceStr / month';
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
    
    final specs = getPropertySpecs(property);
    final displayPrice = _formatIndianPrice(property.price, property.type);
    final isFeatured = featured || (property.id.hashCode.abs() % 3 == 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF2F4F7),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Inset image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 105,
                      height: 105,
                      child: property.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: property.images.first.trim(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF9FAFB),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF9FAFB),
                                child: const Icon(Icons.photo, color: Colors.grey, size: 24),
                              ),
                            )
                          : _LazyPropertyImage(
                              propertyId: property.id,
                              fallback: _fallbackPropertyImage,
                            ),
                    ),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C46E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Right Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      property.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2939),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5C46E8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${specs.sqft}  •  ${specs.bedrooms}  •  ${specs.bathrooms}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${specs.type}  •  ${specs.status}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Heart Toggle
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.pinkAccent : const Color(0xFF98A2B3),
                  size: 22,
                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        placeholder: (context, url) => Container(color: cs.surfaceContainerHighest),
        errorWidget: (context, url, error) => Container(
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.photo, size: 30),
        ),
      ),
      data: (images) => CachedNetworkImage(
        imageUrl: images.isNotEmpty ? images.first : fallback,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: cs.surfaceContainerHighest),
        errorWidget: (context, url, error) => CachedNetworkImage(imageUrl: fallback, fit: BoxFit.cover),
      ),
    );
  }
}
