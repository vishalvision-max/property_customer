import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'autoplay_video_preview.dart';
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
  // Extract square feet from API or description
  String sqft = '';
  if (p.superBuiltUpArea != null && p.superBuiltUpArea! > 0) {
    sqft = '${p.superBuiltUpArea!.toInt()} sqft';
  } else if (p.carpetArea != null && p.carpetArea! > 0) {
    sqft = '${p.carpetArea!.toInt()} sqft';
  } else if (p.builtUpArea != null && p.builtUpArea! > 0) {
    sqft = '${p.builtUpArea!.toInt()} sqft';
  } else {
    final sqftMatch = RegExp(
      r'(\d+)\s*(sqft|sq\.ft\.|sq\s*ft|sq\.yd\.)',
      caseSensitive: false,
    ).firstMatch(p.description);
    if (sqftMatch != null) {
      sqft = '${sqftMatch.group(1)} ${sqftMatch.group(2)}';
    }
  }

  // Extract BHK/bedrooms from API or name or description
  String bedrooms = '';
  if (p.bhk != null && p.bhk! > 0) {
    bedrooms = '${p.bhk} Bed';
  } else if (p.bedrooms != null && p.bedrooms! > 0) {
    bedrooms = '${p.bedrooms} Bed';
  } else {
    final bhkMatch = RegExp(
      r'(\d+)\s*(BHK|Bed|Bedroom)',
      caseSensitive: false,
    ).firstMatch(p.name + p.description);
    if (bhkMatch != null) {
      bedrooms = '${bhkMatch.group(1)} Bed';
    }
  }

  // Extract bathrooms
  String bathrooms = '';
  if (p.bathrooms != null && p.bathrooms! > 0) {
    bathrooms = '${p.bathrooms} Bath';
  } else {
    final bathMatch = RegExp(
      r'(\d+)\s*(Bath|Bathroom)',
      caseSensitive: false,
    ).firstMatch(p.description);
    if (bathMatch != null) {
      bathrooms = '${bathMatch.group(1)} Bath';
    }
  }

  // Balconies
  String balconies = '';
  if (p.balconies != null && p.balconies! > 0) {
    balconies = '${p.balconies}';
  } else {
    final balconyMatch = RegExp(
      r'(\d+)\s*(Balcony|Balconies)',
      caseSensitive: false,
    ).firstMatch(p.description);
    if (balconyMatch != null) {
      balconies = balconyMatch.group(1)!;
    }
  }

  // Parking
  String parking = '';
  if (p.parking != null && p.parking! > 0) {
    parking = '${p.parking}';
  } else if (p.amenities.contains('Parking') || p.amenities.contains('Visitor Parking')) {
    parking = 'Yes';
  }

  // Property Type
  String type = '';
  if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
    type = p.categoryName!.trim();
  } else if (p.propertyKind.trim().isNotEmpty) {
    type = p.propertyKind.trim();
  }
  
  if (p.type.toLowerCase() == 'pg') {
    type = 'PG / Co-Living';
  }

  // Status
  String status = 'Ready to Move';
  if (p.description.toLowerCase().contains('ready to move') ||
      p.availability.isBefore(DateTime.now().add(const Duration(days: 1)))) {
    status = 'Ready to Move';
  } else {
    status = 'Under Construction';
  }

  // Highlights
  List<String> highlights = [];
  highlights.add(type);
  highlights.add(status);

  if (p.facing != null) {
    final facing = p.facing!.trim();
    if (facing.isNotEmpty) {
      final formattedFacing =
          facing[0].toUpperCase() + facing.substring(1).toLowerCase();
      highlights.add('$formattedFacing Facing');
    }
  }

  if (p.furnishing != null && p.furnishing!.trim().isNotEmpty) {
    final furnishing = p.furnishing!.replaceAll('_', ' ').trim();
    highlights.add(
      furnishing
          .split(' ')
          .map(
            (e) => e.isEmpty
                ? e
                : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
          )
          .join(' '),
    );
  }

  highlights = highlights.toSet().toList();

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
          RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
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

    final typeStr = (() {
      final type = specs.type;
      if (type.toLowerCase().contains('plot') ||
          type.toLowerCase().contains('land')) {
        return 'Residential Plot';
      }
      if (type.toLowerCase().contains('commercial') ||
          type.toLowerCase().contains('shop')) {
        return 'Commercial Space';
      }
      String bhkPrefix = '';
      if (property.bhk != null && property.bhk! > 0) {
        bhkPrefix = '${property.bhk} BHK ';
      } else if (property.bedrooms != null && property.bedrooms! > 0) {
        bhkPrefix = '${property.bedrooms} BHK ';
      } else {
        final bhkMatch = RegExp(
          r'(\d+)\s*(BHK|Bed|Bedroom|BH|B)',
          caseSensitive: false,
        ).firstMatch(property.name + property.description);
        if (bhkMatch != null) {
          bhkPrefix = '${int.tryParse(bhkMatch.group(1) ?? '') ?? ''} BHK ';
        }
      }
      return '$bhkPrefix$type';
    })();

    final locationParts = (() {
      final loc = property.location.trim();
      if (loc.isEmpty) return ['Panchkula'];
      final parts = loc
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
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
      return parts;
    })();

    final subAddress = locationParts.isNotEmpty
        ? locationParts.join(', ')
        : 'Panchkula';

    // Calculate Price per sqft for display
    String pricePerSqft = '';
    if (specs.sqft.isNotEmpty) {
      final numMatch = RegExp(
        r'(\d+)',
      ).firstMatch(specs.sqft.replaceAll(',', ''));
      if (numMatch != null) {
        final sqftVal = int.tryParse(numMatch.group(1) ?? '');
        if (sqftVal != null && sqftVal > 0) {
          final pps = property.price / sqftVal;
          if (pps >= 1000) {
            pricePerSqft = '₹${(pps / 1000).toStringAsFixed(1)}k/ sq.ft.';
          } else {
            pricePerSqft = '₹${pps.toInt()}/ sq.ft.';
          }
        }
      }
    }

    final String updatedTimeAgo = (() {
      final date = property.updatedAt ?? property.createdAt;
      if (date == null) return 'Just now';
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    })();

    final String sellerName = (property.ownerName?.trim().isNotEmpty == true)
        ? property.ownerName!.trim().toUpperCase()
        : 'VERIFIED ${(property.listingType?.trim().toUpperCase()) ?? "OWNER"}';

    final String avatarName = (property.ownerName?.trim().isNotEmpty == true)
        ? property.ownerName!.trim()
        : (property.listingType ?? 'Owner');

    bool showTransactionType = false;
    String transactionText = '';
    Color transactionBg = Colors.transparent;
    Color transactionColor = Colors.transparent;

    final pType = property.type.toLowerCase();
    if (pType == 'sale' || pType == 'buy') {
      showTransactionType = true;
      transactionText = 'For Sale';
      transactionBg = const Color(0xFFECFDF3); // Green background
      transactionColor = const Color(0xFF027A48); // Dark green text
    } else if (pType == 'rent') {
      showTransactionType = true;
      transactionText = 'For Rent';
      transactionBg = const Color(0xFFEFF8FF); // Blue background
      transactionColor = const Color(0xFF175CD3); // Dark blue text
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAECF0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── PREMIUM HEADER (Owner / Agent info) ───
              // Container(
              //   color: const Color(0xFF344054),
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 14,
              //     vertical: 10,
              //   ),
              //   child: Row(
              //     children: [
              //       CircleAvatar(
              //         radius: 14,
              //         backgroundColor: Colors.white24,
              //         backgroundImage: NetworkImage(
              //           'https://ui-avatars.com/api/?name=${Uri.encodeComponent(avatarName)}&background=random&color=fff&size=64',
              //         ),
              //       ),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           sellerName,
              //           maxLines: 1,
              //           overflow: TextOverflow.ellipsis,
              //           style: const TextStyle(
              //             color: Colors.white,
              //             fontSize: 10.5,
              //             fontWeight: FontWeight.w800,
              //             letterSpacing: 0.8,
              //           ),
              //         ),
              //       ),
              //       const Icon(
              //         Icons.verified_rounded,
              //         color: Color(0xFFF79009),
              //         size: 16,
              //       ),
              //       const SizedBox(width: 4),
              //       const Text(
              //         'Verified',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 10.5,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // ─── BIG IMAGE WITH GRADIENT OVERLAY ───
              SizedBox(
                height: compact ? 180 : 240,
                child: _PropertyMediaGallery(
                  property: property,
                  isFeatured: isFeatured,
                  fallbackImage: _fallbackPropertyImage,
                  enableVideoPreview: enableVideoPreview,
                ),
              ),

              // ─── CONTENT SECTION ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Price per sqft & Heart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  specs.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),
                              if (showTransactionType) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: transactionBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    transactionText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: transactionColor,
                                    ),
                                  ),
                                ),
                              ],
                              if (pricePerSqft.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  '•',
                                  style: TextStyle(color: Color(0xFF98A2B3)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Price/sq.ft. $pricePerSqft',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
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
                                .toggleRemote(type: 'property', id: property.id)
                                .catchError((_) {
                                  if (!context.mounted) return;
                                  AppSnackbar.showError(
                                    context,
                                    'Failed to update wishlist. Please try again.',
                                  );
                                });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? const Color(0xFFFDF2FA)
                                  : const Color(0xFFF2F4F7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav
                                  ? const Color(0xFFD92D20)
                                  : const Color(0xFF475467),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      typeStr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF344054),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Address
                    // Text(
                    //   property.name.toUpperCase(),
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: const TextStyle(
                    //     fontSize: 13,
                    //     fontWeight: FontWeight.w800,
                    //     color: Color(0xFF344054),
                    //   ),
                    // ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF98A2B3),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 20),

                      // Divider
                      const Divider(
                        color: Color(0xFFEAECF0),
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 16),

                      // Bottom Action Row
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Updated',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                updatedTimeAgo,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {
                              onTap();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              minimumSize: const Size(0, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: const BorderSide(
                                color: Color(0xFF5C46E8),
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF5C46E8),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF039855),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFECFDF3),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.wechat_rounded, // fallback for whatsapp
                                color: Color(0xFF039855),
                                size: 24,
                              ),
                              tooltip: 'WhatsApp',
                              onPressed: () async {
                                final phone = property.ownerPhone?.trim() ?? '';
                                if (phone.isEmpty) return;
                                String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                                if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
                                  cleanPhone = '91$cleanPhone';
                                }
                                final url = Uri.parse('https://wa.me/$cleanPhone');
                                try {
                                  await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
                                } catch (_) {
                                  launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C46E8),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5C46E8,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: 'Call',
                              onPressed: () async {
                                final phone = property.ownerPhone?.trim() ?? '';
                                if (phone.isEmpty) return;
                                final url = Uri.parse('tel:$phone');
                                try {
                                  await launchUrl(url);
                                } catch (_) {}
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
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
          child: const Icon(Icons.photo_outlined, size: 32, color: Colors.grey),
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

class _PropertyMediaGallery extends StatefulWidget {
  final Property property;
  final bool isFeatured;
  final String fallbackImage;
  final bool enableVideoPreview;

  const _PropertyMediaGallery({
    required this.property,
    required this.isFeatured,
    required this.fallbackImage,
    required this.enableVideoPreview,
  });

  @override
  State<_PropertyMediaGallery> createState() => _PropertyMediaGalleryState();
}

class _PropertyMediaGalleryState extends State<_PropertyMediaGallery> {
  int _currentIndex = 0;
  late final List<Map<String, dynamic>> _mediaList;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mediaList = [];
    if (widget.enableVideoPreview) {
      for (final v in widget.property.videos) {
        if (v.trim().isNotEmpty) {
          _mediaList.add({'type': 'video', 'url': v.trim()});
        }
      }
    }
    for (final i in widget.property.images) {
      if (i.trim().isNotEmpty) {
        _mediaList.add({'type': 'image', 'url': i.trim()});
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_mediaList.isEmpty)
          _LazyPropertyImage(
            propertyId: widget.property.id,
            fallback: widget.fallbackImage,
          )
        else
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: _mediaList.length,
            itemBuilder: (context, index) {
              final item = _mediaList[index];
              if (item['type'] == 'video') {
                return AutoplayVideoPreview(
                  key: ValueKey(item['url']),
                  url: item['url'],
                  muted: true,
                  loop: true,
                  autoplay: true,
                  gateByVisibility: false,
                  visibleFractionToPlay: 0.5,
                  fit: BoxFit.cover,
                  loading: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: Container(
                    color: const Color(0xFFF9FAFB),
                    child: const Icon(
                      Icons.video_file,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: item['url'],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: const Color(0xFFF9FAFB)),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF9FAFB),
                  child: const Icon(
                    Icons.photo_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              );
            },
          ),

        // Gradient overlay for bottom elements
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Featured Badge
        if (widget.isFeatured)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF5C46E8),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C46E8).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'FEATURED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

        // Counter Badge
        if (_mediaList.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _mediaList[_currentIndex]['type'] == 'video'
                        ? Icons.play_circle_fill_rounded
                        : Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentIndex + 1} / ${_mediaList.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
