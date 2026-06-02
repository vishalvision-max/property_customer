import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/autoplay_video_preview.dart';

import '../../widgets/property_card.dart'; // to reuse specs extraction and price formatter
import '../../widgets/responsive_item_grid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

const _kPrimary = Color(0xFF5C46E8);
const _fallbackImage =
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80&auto=format&fit=crop';

String _getCleanLocality(String fullLocation) {
  final loc = fullLocation.trim();
  if (loc.isEmpty) return 'Panchkula';
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
    return '${parts[0]}, ${parts[1]}';
  }
  return parts.first;
}

String _getCleanSmallAddress(String fullLocation) {
  final loc = fullLocation.trim();
  if (loc.isEmpty) return 'Panchkula, Haryana';
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

  if (parts.isEmpty) return 'Panchkula, Haryana';

  if (parts.length > 3) {
    return parts.sublist(parts.length - 3).join(', ');
  }
  return parts.join(', ');
}

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  Future<Property>? _future;
  bool _isAmenitiesExpanded = false;
  bool _isHighlightsExpanded = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _future = Future<Property>.microtask(
      () => ref
          .read(propertyNotifierProvider.notifier)
          .fetchDetails(widget.propertyId),
    );
  }

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

  IconData _highlightIcon(String highlight) {
    final s = highlight.toLowerCase();
    if (s.contains('apartment')) return Icons.apartment_outlined;
    if (s.contains('villa')) return Icons.home_outlined;
    if (s.contains('floor')) return Icons.layers_outlined;
    if (s.contains('commercial')) return Icons.storefront_outlined;
    if (s.contains('plot')) return Icons.landscape_outlined;
    if (s.contains('ready')) return Icons.check_circle_outline_rounded;
    if (s.contains('construction')) return Icons.construction_outlined;
    if (s.contains('facing')) return Icons.explore_outlined;
    if (s.contains('furnished')) return Icons.chair_outlined;
    if (s.contains('society')) return Icons.fence_outlined;
    if (s.contains('security')) return Icons.security_outlined;
    return Icons.check_circle_outline;
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pool') || lower.contains('swim')) return Icons.pool;
    if (lower.contains('gym') || lower.contains('fitness'))
      return Icons.fitness_center;
    if (lower.contains('park') || lower.contains('garden')) return Icons.park;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('power') ||
        lower.contains('backup') ||
        lower.contains('generator'))
      return Icons.power;
    if (lower.contains('security') ||
        lower.contains('cctv') ||
        lower.contains('guard'))
      return Icons.security;
    if (lower.contains('lift') || lower.contains('elevator'))
      return Icons.elevator;
    if (lower.contains('club') || lower.contains('lounge'))
      return Icons.meeting_room;
    if (lower.contains('kid') || lower.contains('play'))
      return Icons.child_care;
    if (lower.contains('gas') || lower.contains('pipeline'))
      return Icons.local_fire_department;
    if (lower.contains('water')) return Icons.water_drop;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildThumbnailStrip(BuildContext context, Property p) {
    final videos = p.videos;
    final images = p.images;
    
    final mediaList = <Map<String, dynamic>>[
      for (var i = 0; i < videos.length; i++)
        {'type': 'video', 'url': videos[i], 'index': i},
      for (var i = 0; i < images.length; i++)
        {'type': 'image', 'url': images[i], 'index': i},
    ];

    if (mediaList.length <= 1) return const SizedBox.shrink();

    final maxThumbnails = 4;
    final displayMedia = mediaList.skip(1).take(maxThumbnails).toList();
    final remainingCount = mediaList.length - 1 - displayMedia.length;

    String fallbackImage() {
      final first = images.isNotEmpty ? images.first.trim() : '';
      return first.isEmpty ? _fallbackImage : first;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < displayMedia.length; i++)
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      final item = displayMedia[i];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ZoomGallery(
                            mediaList: mediaList,
                            initialIndex: mediaList.indexOf(item),
                            title: p.name,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: displayMedia[i]['type'] == 'video'
                            ? AutoplayVideoPreview(
                                url: displayMedia[i]['url'],
                                loop: false,
                                fit: BoxFit.cover,
                                visibleFractionToPlay: 0.20,
                                loading: Container(color: Colors.black12),
                                error: CachedNetworkImage(
                                  imageUrl: fallbackImage(),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: displayMedia[i]['url'].trim(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.black12),
                                errorWidget: (context, url, error) =>
                                    Container(color: Colors.black12),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            if (remainingCount > 0)
              SizedBox(
                width: 80,
                child: GestureDetector(
                  onTap: () {
                    final item = mediaList[1 + displayMedia.length];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ZoomGallery(
                          mediaList: mediaList,
                          initialIndex: mediaList.indexOf(item),
                          title: p.name,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          (() {
                            final item = mediaList[1 + displayMedia.length];
                            if (item['type'] == 'video') {
                              return AutoplayVideoPreview(
                                url: item['url'],
                                loop: false,
                                fit: BoxFit.cover,
                                visibleFractionToPlay: 0.20,
                                loading: Container(color: Colors.black12),
                                error: CachedNetworkImage(
                                  imageUrl: fallbackImage(),
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return CachedNetworkImage(
                                imageUrl: item['url'].trim(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.black12),
                                errorWidget: (context, url, error) =>
                                    Container(color: Colors.black12),
                              );
                            }
                          })(),
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Text(
                                '+$remainingCount\nMedia',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsRow(PropertySpecs specs) {
    Widget specColumn({
      required IconData icon,
      required String value,
      required String label,
    }) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF667085), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      );
    }

    final List<Widget> items = [];

    if (specs.sqft.isNotEmpty) {
      items.add(specColumn(
        icon: Icons.square_foot_outlined,
        value: specs.sqft,
        label: 'Super Built-up',
      ));
    }
    if (specs.bedrooms.isNotEmpty) {
      items.add(specColumn(
        icon: Icons.king_bed_outlined,
        value: specs.bedrooms.replaceAll(RegExp(r'\s*Bed'), ''),
        label: 'Bedrooms',
      ));
    }
    if (specs.bathrooms.isNotEmpty) {
      items.add(specColumn(
        icon: Icons.bathtub_outlined,
        value: specs.bathrooms.replaceAll(RegExp(r'\s*Bath'), ''),
        label: 'Bathrooms',
      ));
    }
    if (specs.balconies.isNotEmpty) {
      items.add(specColumn(
        icon: Icons.balcony_outlined,
        value: specs.balconies,
        label: 'Balcony',
      ));
    }
    if (specs.parking.isNotEmpty) {
      items.add(specColumn(
        icon: Icons.local_parking_outlined,
        value: specs.parking,
        label: 'Parking',
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }

  Widget _buildHighlights(PropertySpecs specs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'furnishing',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveItemGrid<String>(
            items: specs.highlights,
            fixedColumns: 3,
            spacing: 8,
            runSpacing: 8,
            isCollapsible: true,
            isExpanded: _isHighlightsExpanded,
            onToggle: () {
              setState(() {
                _isHighlightsExpanded = !_isHighlightsExpanded;
              });
            },
            itemBuilder: (context, h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _highlightIcon(h),
                      color: const Color(0xFF5C46E8),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        h,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF344054),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow(String title, String value) {
    if (value.trim().isEmpty || value.trim() == 'null' || value.trim() == '0') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDetails(Property p) {
    final List<Widget> rows = [];
    if (p.securityDeposit != null && p.securityDeposit! > 0) {
      rows.add(_buildTermsRow('Security Deposit', '₹${p.securityDeposit}'));
    }
    if (p.bookingAmount != null && p.bookingAmount! > 0) {
      rows.add(_buildTermsRow('Booking Amount', '₹${p.bookingAmount}'));
    }
    if (p.parkingCharges != null && p.parkingCharges! > 0) {
      rows.add(_buildTermsRow('Parking Charges', '₹${p.parkingCharges}'));
    }
    if (p.paintingCharges != null && p.paintingCharges! > 0) {
      rows.add(_buildTermsRow('Painting Charges', '₹${p.paintingCharges}'));
    }
    if (p.lockInPeriod != null && p.lockInPeriod!.isNotEmpty) {
      rows.add(_buildTermsRow('Lock-in Period', p.lockInPeriod!));
    }
    if (p.availableFrom != null && p.availableFrom!.isNotEmpty) {
      rows.add(_buildTermsRow('Available From', p.availableFrom!));
    }
    if (p.priceNegotiable == true) {
      rows.add(_buildTermsRow('Price Negotiable', 'Yes'));
    }

    if (p.furnishing != null && p.furnishing!.trim().isNotEmpty) {
      final f = p.furnishing!
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (e) => e.isEmpty
                ? e
                : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
          )
          .join(' ');
      rows.add(_buildTermsRow('Furnishing', f));
    }
    
    if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
      rows.add(_buildTermsRow('Property Type', p.categoryName!));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financials & Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref
        .watch(propertyNotifierProvider.notifier)
        .getById(widget.propertyId);

    return FutureBuilder<Property>(
      future: _future,
      initialData: cached,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _kPrimary)),
          );
        }

        final isAuthed = ref.watch(authProvider).user != null;
        final isFav = ref.watch(
          favoritesProvider.select((s) => s.contains(p.id)),
        );

        void toggleFavorite() {
          if (!isAuthed) {
            AppSnackbar.showError(context, 'Please login to add favorites');
            context.push(
              '/login?from=${Uri.encodeComponent('/property/${p.id}')}',
            );
            return;
          }
          ref
              .read(favoritesProvider.notifier)
              .toggleRemote(type: 'property', id: p.id)
              .catchError((_) {
                if (!context.mounted) return;
                AppSnackbar.showError(
                  context,
                  'Failed to update wishlist. Please try again.',
                );
              });
        }

        final specs = getPropertySpecs(p);
        final displayPrice = _formatIndianPrice(p.price, p.type);

        void scheduleVisit() {
          if (!isAuthed) {
            AppSnackbar.showError(context, 'Please login to schedule a visit');
            context.push(
              '/login?from=${Uri.encodeComponent('/schedule/${p.id}')}',
            );
            return;
          }
          context.push('/schedule/${p.id}');
        }

        void handleCall() async {
          if (!isAuthed) {
            AppSnackbar.showError(
              context,
              'Please login to contact the agent.',
            );
            context.push(
              '/login?from=${Uri.encodeComponent('/property/${p.id}')}',
            );
            return;
          }
          final phone = p.ownerPhone?.trim() ?? '';
          if (phone.isEmpty) {
            AppSnackbar.showMessage(
              context,
              'Please schedule a visit to know more about this property.',
            );
            return;
          }
          final uri = Uri.parse('tel:$phone');
          try {
            await launchUrl(uri);
          } catch (e) {
            if (!context.mounted) return;
            AppSnackbar.showError(context, 'Could not open the phone dialer.');
          }
        }

        void handleChat() async {
          if (!isAuthed) {
            AppSnackbar.showError(
              context,
              'Please login to contact the agent.',
            );
            context.push(
              '/login?from=${Uri.encodeComponent('/property/${p.id}')}',
            );
            return;
          }
          final phone = p.ownerPhone?.trim() ?? '';
          if (phone.isEmpty) {
            AppSnackbar.showMessage(
              context,
              'Please schedule a visit to know more about this property.',
            );
            return;
          }
          String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
            cleanPhone = '91$cleanPhone';
          }
          final message = Uri.encodeComponent(
            'Hi, I am interested in your property: "${(() {
              final type = specs.type;
              final cleanLocality = _getCleanLocality(p.location);
              if (type.toLowerCase().contains('plot') || type.toLowerCase().contains('land')) {
                return 'Residential Plot in $cleanLocality';
              }
              if (type.toLowerCase().contains('commercial') || type.toLowerCase().contains('shop')) {
                return 'Commercial Space in $cleanLocality';
              }
              int bhkCount = 3;
              if (p.bhk != null && p.bhk! > 0) {
                bhkCount = p.bhk!;
              } else if (p.bedrooms != null && p.bedrooms! > 0) {
                bhkCount = p.bedrooms!;
              } else {
                final bhkMatch = RegExp(r'(\d+)\s*(BHK|Bed|Bedroom|BH|B)', caseSensitive: false).firstMatch(p.name + p.description);
                if (bhkMatch != null) {
                  bhkCount = int.tryParse(bhkMatch.group(1) ?? '3') ?? 3;
                }
              }
              return '$bhkCount BHK $type in $cleanLocality';
            })()}" (${p.location}).',
          );

          final uri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
          try {
            // First try launching directly as external application for WhatsApp
            await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          } catch (e) {
            try {
              // Fallback to standard external application
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e2) {
              if (!context.mounted) return;
              AppSnackbar.showError(context, 'Could not open WhatsApp.');
            }
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Media Slider
                    _HeroMediaLight(
                      videos: p.videos,
                      images: p.images,
                      title: p.name,
                      onBack: () => context.pop(),
                      onShare: () => AppSnackbar.showMessage(
                        context,
                        'Sharing property listing details...',
                      ),
                      onToggleFavorite: toggleFavorite,
                      isFavorited: isFav,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    ),

                    // Thumbnail Strip
                    _buildThumbnailStrip(context, p),

                    // Name/Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        (() {
                          final type = specs.type;
                          final cleanLocality = _getCleanLocality(p.location);
                          if (type.toLowerCase().contains('plot') ||
                              type.toLowerCase().contains('land')) {
                            return 'Residential Plot in $cleanLocality';
                          }
                          if (type.toLowerCase().contains('commercial') ||
                              type.toLowerCase().contains('shop')) {
                            return 'Commercial Space in $cleanLocality';
                          }
                          int bhkCount = 3;
                          if (p.bhk != null && p.bhk! > 0) {
                            bhkCount = p.bhk!;
                          } else if (p.bedrooms != null && p.bedrooms! > 0) {
                            bhkCount = p.bedrooms!;
                          } else {
                            final bhkMatch = RegExp(
                              r'(\d+)\s*(BHK|Bed|Bedroom|BH|B)',
                              caseSensitive: false,
                            ).firstMatch(p.name + p.description);
                            if (bhkMatch != null) {
                              bhkCount =
                                  int.tryParse(bhkMatch.group(1) ?? '3') ?? 3;
                            }
                          }
                          return '$bhkCount BHK $type in $cleanLocality';
                        })(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D2939),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),

                    // Subtitle / Location
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _getCleanSmallAddress(p.location),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),

                    // Price
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        displayPrice,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5C46E8),
                        ),
                      ),
                    ),

                    // Specs Grid Row
                    _buildSpecsRow(specs),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F4F7),
                      ),
                    ),

                    // Property Highlights Wrap
                    _buildHighlights(specs),

                    const SizedBox(height: 20),

                    // Amenities Section
                    if (p.amenities.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Amenities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ResponsiveItemGrid<String>(
                              items: p.amenities,
                              fixedColumns: 3,
                              spacing: 8,
                              runSpacing: 8,
                              isCollapsible: true,
                              isExpanded: _isAmenitiesExpanded,
                              onToggle: () {
                                setState(() {
                                  _isAmenitiesExpanded = !_isAmenitiesExpanded;
                                });
                              },
                              itemBuilder: (context, a) {
                                final clean = a.replaceAll('_', ' ').trim();

                                final formatted = clean
                                    .split(' ')
                                    .map(
                                      (w) => w.isEmpty
                                          ? w
                                          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
                                    )
                                    .join(' ');

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE4E1FC),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAmenityIcon(clean),
                                        color: const Color(0xFF5C46E8),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          formatted,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF344054),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    if (p.amenities.isNotEmpty) const SizedBox(height: 20),
                    
                    // Extra Details (Financials, Terms)
                    _buildExtraDetails(p),

                    const SizedBox(height: 8),

                    // // Furnishing Section
                    // if (p.furnishing != null && p.furnishing!.trim().isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         const Text(
                    //           'Furnishing',
                    //           style: TextStyle(
                    //             fontSize: 16,
                    //             fontWeight: FontWeight.w800,
                    //             color: Color(0xFF1D2939),
                    //           ),
                    //         ),

                    //         const SizedBox(height: 12),

                    //         Container(
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 12,
                    //             vertical: 10,
                    //           ),
                    //           decoration: BoxDecoration(
                    //             color: const Color(0xFFF2F4F7),
                    //             borderRadius: BorderRadius.circular(8),
                    //           ),
                    //           child: Text(
                    //             p.furnishing!
                    //                 .replaceAll('_', ' ')
                    //                 .split(' ')
                    //                 .map(
                    //                   (e) => e.isEmpty
                    //                       ? e
                    //                       : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
                    //                 )
                    //                 .join(' '),
                    //             style: const TextStyle(
                    //               fontSize: 13,
                    //               fontWeight: FontWeight.w700,
                    //               color: Color(0xFF344054),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F4F7),
                      ),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final text = p.description.isEmpty
                                  ? 'No description provided.'
                                  : p.description;

                              // Style of our description text
                              const textStyle = TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF667085),
                                height: 1.6,
                              );

                              // Use TextPainter to check if it exceeds 3 lines in the given width
                              final span = TextSpan(
                                text: text,
                                style: textStyle,
                              );
                              final tp = TextPainter(
                                text: span,
                                maxLines: 3,
                                textDirection: TextDirection.ltr,
                              );
                              tp.layout(maxWidth: constraints.maxWidth);
                              final isExceeding = tp.didExceedMaxLines;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    maxLines: _isDescriptionExpanded ? null : 3,
                                    overflow: _isDescriptionExpanded
                                        ? null
                                        : TextOverflow.ellipsis,
                                    style: textStyle,
                                  ),
                                  if (isExceeding) ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isDescriptionExpanded =
                                              !_isDescriptionExpanded;
                                        });
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _isDescriptionExpanded
                                                    ? 'Show Less'
                                                    : 'Read More',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF5C46E8),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                _isDescriptionExpanded
                                                    ? Icons
                                                          .keyboard_arrow_up_rounded
                                                    : Icons
                                                          .keyboard_arrow_down_rounded,
                                                size: 16,
                                                color: const Color(0xFF5C46E8),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // Bottom Action Buttons bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFF2F4F7),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: handleChat,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF5C46E8),
                                  width: 1,
                                ),
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Color(0xFF5C46E8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Chat',
                                      style: TextStyle(
                                        color: Color(0xFF5C46E8),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: scheduleVisit,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF5C46E8),
                                  width: 1,
                                ),
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Text(
                                  'Schedule',
                                  style: TextStyle(
                                    color: Color(0xFF5C46E8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: handleCall,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _kPrimary,
                              ),
                              child: Center(
                                child: Text(
                                  p.ownerPhone != null && p.ownerPhone!.trim().isNotEmpty
                                    ? 'Call ${p.ownerPhone}'
                                    : 'Call Agent',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroMediaLight extends StatefulWidget {
  final List<String> videos;
  final List<String> images;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;
  final bool isLoading;

  const _HeroMediaLight({
    required this.videos,
    required this.images,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
    required this.isFavorited,
    required this.isLoading,
  });

  @override
  State<_HeroMediaLight> createState() => _HeroMediaLightState();
}

class _HeroMediaLightState extends State<_HeroMediaLight> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final videos = widget.videos;
    final images = widget.images.isEmpty ? const <String>[''] : widget.images;
    final total = videos.length + images.length;

    final mediaList = <Map<String, dynamic>>[
      for (var i = 0; i < videos.length; i++)
        {'type': 'video', 'url': videos[i]},
      for (var i = 0; i < images.length; i++)
        {'type': 'image', 'url': images[i]},
    ];

    String fallbackImage() {
      final first = images.isNotEmpty ? images.first.trim() : '';
      return first.isEmpty ? _fallbackImage : first;
    }

    return SizedBox(
      height: 290,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isLoading && widget.images.isEmpty)
            Shimmer.fromColors(
              baseColor: const Color(0xFFF2F4F7),
              highlightColor: const Color(0xFFEAECF0),
              child: Container(
                height: 290,
                width: double.infinity,
                color: Colors.white,
              ),
            )
          else
            CarouselSlider(
              options: CarouselOptions(
                height: 290,
                viewportFraction: 1,
                enableInfiniteScroll: total > 1,
                onPageChanged: (i, _) => setState(() => _index = i),
              ),
              items: [
                for (final v in videos)
                  GestureDetector(
                    onTap: () {
                      final idx = videos.indexOf(v);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ZoomGallery(
                            mediaList: mediaList,
                            initialIndex: idx,
                            title: widget.title,
                          ),
                        ),
                      );
                    },
                    child: AutoplayVideoPreview(
                      url: v,
                      loop: false,
                      fit: BoxFit.cover,
                      visibleFractionToPlay: 0.20,
                      loading: Container(color: Colors.black12),
                      error: CachedNetworkImage(
                        imageUrl: fallbackImage(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                for (var i = 0; i < images.length; i++)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ZoomGallery(
                          mediaList: mediaList,
                          initialIndex: videos.length + i,
                          title: widget.title,
                        ),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[i].trim().isEmpty
                          ? _fallbackImage
                          : images[i].trim(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                      errorWidget: (context, url, error) => CachedNetworkImage(
                        imageUrl: _fallbackImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
              ],
            ),

          // Floating overlay controls
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          color: widget.isFavorited
                              ? Colors.pinkAccent
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (total > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1}/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomGallery extends StatefulWidget {
  final List<Map<String, dynamic>> mediaList;
  final int initialIndex;
  final String title;

  const _ZoomGallery({
    required this.mediaList,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_ZoomGallery> createState() => _ZoomGalleryState();
}

class _ZoomGalleryState extends State<_ZoomGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final maxIdx = (widget.mediaList.length - 1).clamp(0, 999999);
    _index = widget.initialIndex.clamp(0, maxIdx);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.mediaList.isEmpty ? const [{'type': 'image', 'url': ''}] : widget.mediaList;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${media.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: media.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final item = media[i];
          final type = item['type'];
          final url = (item['url'] as String?)?.trim() ?? '';
          final finalUrl = url.isEmpty ? _fallbackImage : url;

          if (type == 'video') {
            return Center(
              child: AutoplayVideoPreview(
                url: finalUrl,
                muted: false,
                loop: true,
                autoplay: true,
                gateByVisibility: true,
                visibleFractionToPlay: 0.5,
                fit: BoxFit.contain,
                loading: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: CachedNetworkImage(
                  imageUrl: _fallbackImage,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }

          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: finalUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: _fallbackImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
