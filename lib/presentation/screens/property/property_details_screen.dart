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
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _orangeTint = Color(0xFFFFF1E0);
const _fallbackImage =
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80&auto=format&fit=crop';

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

String _formatIndianPrice(int price, String type) {
  final t = type.toLowerCase();
  if (t == 'rent' ||
      t == 'lease' ||
      t == 'pg' ||
      t == 'co-living' ||
      t == 'co-livin') {
    if (price >= 100000) {
      double lakhs = price / 100000.0;
      return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh/mo';
    }
    return '₹$price/mo';
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

IconData _getAmenityIcon(String amenity) {
  final a = amenity.toLowerCase();
  if (a.contains('park')) return Icons.local_parking_rounded;
  if (a.contains('pool') || a.contains('swim')) return Icons.pool_rounded;
  if (a.contains('gym') || a.contains('fitness'))
    return Icons.fitness_center_rounded;
  if (a.contains('restaurant') || a.contains('dining'))
    return Icons.restaurant_rounded;
  if (a.contains('wifi') || a.contains('internet') || a.contains('network')) {
    return Icons.wifi_rounded;
  }
  if (a.contains('pet')) return Icons.pets_rounded;
  if (a.contains('sport')) return Icons.sports_tennis_rounded;
  if (a.contains('laundry')) return Icons.local_laundry_service_rounded;
  if (a.contains('security') || a.contains('guard'))
    return Icons.security_rounded;
  if (a.contains('lift') || a.contains('elevator'))
    return Icons.elevator_rounded;
  if (a.contains('power') || a.contains('backup') || a.contains('electric')) {
    return Icons.bolt_rounded;
  }
  if (a.contains('water')) return Icons.water_drop_rounded;
  if (a.contains('gas')) return Icons.gas_meter_rounded;
  if (a.contains('garden') || a.contains('park')) return Icons.park_rounded;
  if (a.contains('play')) return Icons.sports_soccer_rounded;
  return Icons.check_circle_outline_rounded;
}

String _titleCase(String s) {
  final clean = s.replaceAll('_', ' ').trim();
  return clean
      .split(' ')
      .map(
        (w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
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

  @override
  void initState() {
    super.initState();
    _future = Future.microtask(
      () => ref
          .read(propertyNotifierProvider.notifier)
          .fetchDetails(widget.propertyId),
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
            body: Center(child: CircularProgressIndicator(color: _orange)),
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
            'Hi, I am interested in your property: "${p.name}" (${p.location}).',
          );
          final uri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          } catch (e) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e2) {
              if (!context.mounted) return;
              AppSnackbar.showError(context, 'Could not open WhatsApp.');
            }
          }
        }

        // Deterministic-but-fake review count — no real reviews backend exists yet.
        final fakeReviewCount = 100 + (p.id.hashCode.abs() % 900);
        final facilities = <String>{
          ...p.amenities,
          ...p.furnishingsList,
        }.toList();
        final categoryLabel =
            (p.categoryName?.trim().isNotEmpty == true
                    ? p.categoryName!.trim()
                    : p.propertyKind.trim().isNotEmpty
                    ? p.propertyKind.trim()
                    : 'Property')
                .toUpperCase();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroMedia(
                      videos: p.videos,
                      images: p.images,
                      title: p.name,
                      onBack: () => context.pop(),
                      onShare: () {
                        final priceString = _formatIndianPrice(p.price, p.type);
                        final shareText =
                            '🏡 *Check out this amazing property!*\n\n'
                            '*${p.name}*\n'
                            '📍 Location: ${p.location}\n'
                            '💰 Price: $priceString\n\n'
                            '📱 Download the Vision Vivante Property app to view full details and photos!';
                        Share.share(shareText, subject: p.name);
                      },
                      onToggleFavorite: toggleFavorite,
                      isFavorited: isFav,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    ),

                    // ── Title + category pill + rating ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _orangeTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              categoryLabel,
                              style: const TextStyle(
                                color: _orange,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.star_rounded,
                            color: _orange,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '4.8 (${fakeReviewCount.toString()} reviews)',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stat chips: beds / bath / sqft ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (specs.bedrooms.isNotEmpty)
                            _StatChip(
                              icon: Icons.bed_rounded,
                              label:
                                  '${specs.bedrooms.replaceAll(RegExp(r'\s*Bed'), '')} Beds',
                            ),
                          if (specs.bathrooms.isNotEmpty)
                            _StatChip(
                              icon: Icons.bathtub_rounded,
                              label:
                                  '${specs.bathrooms.replaceAll(RegExp(r'\s*Bath'), '')} bath',
                            ),
                          if (specs.sqft.isNotEmpty)
                            _StatChip(
                              icon: Icons.aspect_ratio_rounded,
                              label: specs.sqft,
                            ),
                        ],
                      ),
                    ),

                    _SectionDivider(),

                    // ── Agent ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agent',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _orange.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  (p.ownerName?.trim().isNotEmpty == true
                                          ? p.ownerName!.trim()[0]
                                          : 'O')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: _orange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.ownerName?.trim().isNotEmpty == true
                                          ? p.ownerName!.trim()
                                          : 'Property Owner',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Text(
                                      'Owner',
                                      style: TextStyle(
                                        color: _grey,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _CircleIconButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                onTap: handleChat,
                              ),
                              const SizedBox(width: 10),
                              _CircleIconButton(
                                icon: Icons.call_outlined,
                                onTap: handleCall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _SectionDivider(),

                    // ── Overview ──
                    if (p.description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.description.trim(),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _grey,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (p.description.trim().isNotEmpty) _SectionDivider(),

                    // ── Facilities ──
                    if (facilities.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Facilities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 18,
                              runSpacing: 16,
                              children: [
                                for (final f in facilities.take(8))
                                  _FacilityItem(
                                    icon: _getAmenityIcon(f),
                                    label: _titleCase(f),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    if (facilities.isNotEmpty) _SectionDivider(),

                    // ── Gallery ──
                    if (p.images.length + p.videos.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildGalleryStrip(context, p),
                          ],
                        ),
                      ),

                    if (p.images.length + p.videos.length > 1)
                      _SectionDivider(),

                    // ── Location ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: _orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.location.trim().isEmpty
                                      ? _getCleanSmallAddress(p.location)
                                      : p.location.trim(),
                                  style: const TextStyle(
                                    color: _grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _LocationPlaceholder(),
                        ],
                      ),
                    ),

                    _SectionDivider(),

                    // ── Reviews ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: _orange,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '4.8 ($fakeReviewCount reviews)',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'See All',
                            style: TextStyle(
                              color: _orange,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 140),
                  ],
                ),
              ),

              // ── Sticky bottom price + booking bar ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PRICE',
                              style: TextStyle(
                                color: _grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              displayPrice,
                              style: const TextStyle(
                                color: _orange,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: Material(
                              color: _orange,
                              borderRadius: BorderRadius.circular(26),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: scheduleVisit,
                                child: const Center(
                                  child: Text(
                                    'Booking Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
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

  Widget _buildGalleryStrip(BuildContext context, Property p) {
    final videos = p.videos;
    final images = p.images;

    final mediaList = <Map<String, dynamic>>[
      for (var i = 0; i < videos.length; i++)
        {'type': 'video', 'url': videos[i]},
      for (var i = 0; i < images.length; i++)
        {'type': 'image', 'url': images[i]},
    ];

    const maxThumbnails = 3;
    final displayMedia = mediaList.take(maxThumbnails).toList();
    final remainingCount = mediaList.length - displayMedia.length;

    String fallbackImage() {
      final first = images.isNotEmpty ? images.first.trim() : '';
      return first.isEmpty ? _fallbackImage : first;
    }

    Widget mediaThumb(Map<String, dynamic> item) {
      if (item['type'] == 'video') {
        return AutoplayVideoPreview(
          url: item['url'],
          loop: false,
          fit: BoxFit.cover,
          visibleFractionToPlay: 0.20,
          loading: Container(color: const Color(0xFFF2F4F7)),
          error: CachedNetworkImage(
            imageUrl: fallbackImage(),
            fit: BoxFit.cover,
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: (item['url'] as String).trim(),
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(color: const Color(0xFFF2F4F7)),
        errorWidget: (context, url, error) =>
            Container(color: const Color(0xFFF2F4F7)),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < displayMedia.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i == displayMedia.length - 1 ? 0 : 10,
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ZoomGallery(
                      mediaList: mediaList,
                      initialIndex: i,
                      title: p.name,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        mediaThumb(displayMedia[i]),
                        if (i == displayMedia.length - 1 && remainingCount > 0)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Text(
                                '$remainingCount+',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
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
          ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F7)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _orangeTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _orange, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FacilityItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _orangeTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _orange, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _orange, width: 1.4),
        ),
        child: Icon(icon, color: _orange, size: 17),
      ),
    );
  }
}

/// Decorative placeholder — the API doesn't expose lat/lng for this property,
/// so this is not a live/interactive map. Wire up real geocoding + a
/// GoogleMap widget here if precise coordinates become available.
class _LocationPlaceholder extends StatelessWidget {
  const _LocationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HERO MEDIA — full-bleed carousel + dot indicators
// ─────────────────────────────────────────────────────────────
class _HeroMedia extends StatefulWidget {
  final List<String> videos;
  final List<String> images;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;
  final bool isLoading;

  const _HeroMedia({
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
  State<_HeroMedia> createState() => _HeroMediaState();
}

class _HeroMediaState extends State<_HeroMedia> {
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
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isLoading && widget.images.isEmpty)
            Shimmer.fromColors(
              baseColor: const Color(0xFFF2F4F7),
              highlightColor: const Color(0xFFEAECF0),
              child: Container(
                height: 340,
                width: double.infinity,
                color: Colors.white,
              ),
            )
          else
            CarouselSlider(
              options: CarouselOptions(
                height: 340,
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
                _HeroIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: widget.onBack,
                ),
                Row(
                  children: [
                    _HeroIconButton(
                      icon: widget.isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: widget.isFavorited
                          ? const Color(0xFFE0245E)
                          : _navy,
                      onTap: widget.onToggleFavorite,
                    ),
                    const SizedBox(width: 8),
                    _HeroIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: widget.onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (total > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: active ? 18 : 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: active
                          ? _orange
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.color = _navy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ZOOM GALLERY — full-screen pinch-zoom viewer
// ─────────────────────────────────────────────────────────────
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
  late int _index;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.mediaList.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.mediaList.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final item = widget.mediaList[i];
          if (item['type'] == 'video') {
            return AutoplayVideoPreview(
              url: item['url'],
              autoplay: true,
              loop: true,
              gateByVisibility: true,
              fit: BoxFit.contain,
              loading: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: const Center(
                child: Icon(Icons.broken_image, color: Colors.white),
              ),
            );
          }
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: (item['url'] as String).trim().isEmpty
                  ? _fallbackImage
                  : (item['url'] as String).trim(),
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
