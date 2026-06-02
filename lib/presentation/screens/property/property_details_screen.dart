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
import '../../widgets/related_property_card.dart';
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
  bool _isFurnishingsExpanded = false;
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
      items.add(
        specColumn(
          icon: Icons.square_foot_outlined,
          value: specs.sqft,
          label: 'Super Built-up',
        ),
      );
    }
    if (specs.bedrooms.isNotEmpty) {
      items.add(
        specColumn(
          icon: Icons.king_bed_outlined,
          value: specs.bedrooms.replaceAll(RegExp(r'\s*Bed'), ''),
          label: 'Bedrooms',
        ),
      );
    }
    if (specs.bathrooms.isNotEmpty) {
      items.add(
        specColumn(
          icon: Icons.bathtub_outlined,
          value: specs.bathrooms.replaceAll(RegExp(r'\s*Bath'), ''),
          label: 'Bathrooms',
        ),
      );
    }
    if (specs.balconies.isNotEmpty) {
      items.add(
        specColumn(
          icon: Icons.balcony_outlined,
          value: specs.balconies,
          label: 'Balcony',
        ),
      );
    }
    if (specs.parking.isNotEmpty) {
      items.add(
        specColumn(
          icon: Icons.local_parking_outlined,
          value: specs.parking,
          label: 'Parking',
        ),
      );
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
            'Facilities',
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

  IconData _getDetailIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('security') || t.contains('deposit'))
      return Icons.security_outlined;
    if (t.contains('booking')) return Icons.payment_outlined;
    if (t.contains('parking')) return Icons.local_parking_outlined;
    if (t.contains('painting')) return Icons.format_paint_outlined;
    if (t.contains('lock')) return Icons.lock_outline;
    if (t.contains('available') || t.contains('from'))
      return Icons.event_available_outlined;
    if (t.contains('negotiable')) return Icons.handshake_outlined;
    if (t.contains('furnishing')) return Icons.chair_outlined;
    if (t.contains('type')) return Icons.home_work_outlined;
    if (t.contains('area')) return Icons.aspect_ratio_outlined;
    if (t.contains('facing')) return Icons.explore_outlined;
    if (t.contains('tag')) return Icons.local_offer_outlined;
    if (t.contains('bhk') || t.contains('bed')) return Icons.king_bed_outlined;
    if (t.contains('bath')) return Icons.bathtub_outlined;
    if (t.contains('balcon')) return Icons.balcony_outlined;
    if (t.contains('floor')) return Icons.layers_outlined;
    if (t.contains('age')) return Icons.history_outlined;
    if (t.contains('maintenance')) return Icons.build_circle_outlined;
    if (t.contains('ownership')) return Icons.real_estate_agent_outlined;
    if (t.contains('corner')) return Icons.turn_right_outlined;
    if (t.contains('room')) return Icons.door_front_door_outlined;
    return Icons.info_outline;
  }

  Widget _buildTermsRow(String title, String value, BuildContext context) {
    if (value.trim().isEmpty || value.trim() == 'null' || value.trim() == '0') {
      return const SizedBox.shrink();
    }

    // Third width minus spacing
    final cardWidth = (MediaQuery.of(context).size.width - 32 - 24) / 3;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDetailIcon(title),
                size: 14,
                color: const Color(0xFF98A2B3),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667085),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDetails(BuildContext context, Property p) {
    final List<Widget> rows = [];
    if (p.securityDeposit != null && p.securityDeposit! > 0) {
      rows.add(
        _buildTermsRow('Security Deposit', '₹${p.securityDeposit}', context),
      );
    }
    if (p.paintingCharges != null && p.paintingCharges! > 0) {
      rows.add(
        _buildTermsRow('Painting Charges', '₹${p.paintingCharges}', context),
      );
    }
    if (p.lockInPeriod != null && p.lockInPeriod!.isNotEmpty) {
      rows.add(_buildTermsRow('Lock-in Period', p.lockInPeriod!, context));
    }
    if (p.availableFrom != null && p.availableFrom!.isNotEmpty) {
      rows.add(_buildTermsRow('Available From', p.availableFrom!, context));
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
      rows.add(_buildTermsRow('Furnishing', f, context));
    }

    if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
      rows.add(_buildTermsRow('Property Type', p.categoryName!, context));
    }
    if (p.facing != null && p.facing!.trim().isNotEmpty) {
      rows.add(
        _buildTermsRow(
          'Facing',
          '${p.facing![0].toUpperCase()}${p.facing!.substring(1)}',
          context,
        ),
      );
    }
    if (p.promotionTags != null && p.promotionTags!.trim().isNotEmpty) {
      rows.add(_buildTermsRow('Promotion Tags', p.promotionTags!, context));
    }

    void addMapDetails(Map<String, dynamic>? map) {
      if (map == null) return;
      map.forEach((k, v) {
        if (k == 'id' ||
            k == 'property_id' ||
            k == 'created_at' ||
            k == 'updated_at' ||
            k == 'facing' ||
            k == 'furnishing' ||
            k == 'carpet_area' ||
            k == 'built_up_area' ||
            k == 'super_built_up_area' ||
            k == 'additional_rooms' ||
            k == 'bhk' ||
            k == 'bedrooms' ||
            k == 'bathrooms' ||
            k == 'balconies' ||
            k == 'floor' ||
            k == 'total_floors' ||
            k == 'property_age' ||
            k == 'property_age_range' ||
            k == 'age' ||
            k == 'age_range' ||
            k == 'maintenance_charges' ||
            k == 'maintenance_charge' ||
            k == 'is_price_negotiable' ||
            k == 'price_negotiable' ||
            k == 'parking' ||
            k == 'parking_charges' ||
            k.endsWith('_unit'))
          return;
        if (v == null ||
            v == '' ||
            v == 0 ||
            v == false ||
            (v is List && v.isEmpty))
          return;
        if (k.endsWith('_area') && p.area != null)
          return; // avoid duplicate area if it matches
        final formattedKey = k
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}',
            )
            .join(' ');

        String valStr = v.toString();
        if (v == true) {
          valStr = 'Yes';
        } else if (v is List) {
          valStr = v
              .map((e) {
                return e
                    .toString()
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map(
                      (w) => w.isEmpty
                          ? w
                          : '${w[0].toUpperCase()}${w.substring(1)}',
                    )
                    .join(' ');
              })
              .join(', ');
        }

        rows.add(_buildTermsRow(formattedKey, valStr, context));
      });
    }

    addMapDetails(p.plotDetails);
    addMapDetails(p.pgDetails);
    addMapDetails(p.officeDetails);
    addMapDetails(p.shopDetails);
    addMapDetails(p.warehouseDetails);
    addMapDetails(p.residentialDetails);

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
          Wrap(spacing: 12, runSpacing: 12, children: rows),
        ],
      ),
    );
  }

  Widget _buildAdditionalRooms(Property p) {
    List<String> rooms = [];
    if (p.residentialDetails != null &&
        p.residentialDetails!['additional_rooms'] is List) {
      rooms = List<String>.from(p.residentialDetails!['additional_rooms']);
    }
    if (rooms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Rooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rooms.map((r) {
              final formatted = r
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (w) => w.isEmpty
                        ? w
                        : '${w[0].toUpperCase()}${w.substring(1)}',
                  )
                  .join(' ');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB2DDFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.door_front_door_outlined,
                      size: 14,
                      color: Color(0xFF175CD3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatted,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF175CD3),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaDetails(BuildContext context, Property p) {
    final List<Widget> rows = [];

    if (p.superBuiltUpArea != null && p.superBuiltUpArea! > 0) {
      rows.add(
        _buildTermsRow(
          'Super Built-up Area',
          '${p.superBuiltUpArea} sqft',
          context,
        ),
      );
    }
    if (p.builtUpArea != null && p.builtUpArea! > 0) {
      rows.add(
        _buildTermsRow('Built-up Area', '${p.builtUpArea} sqft', context),
      );
    }
    if (p.carpetArea != null && p.carpetArea! > 0) {
      rows.add(_buildTermsRow('Carpet Area', '${p.carpetArea} sqft', context));
    }
    if (p.area != null && p.area! > 0) {
      rows.add(
        _buildTermsRow(
          'Plot Area',
          '${p.area} ${p.areaUnit ?? "sqft"}',
          context,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Area Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: rows),
        ],
      ),
    );
  }

  Widget _buildPropertyDetails(BuildContext context, Property p) {
    final List<Widget> rows = [];
    final res = p.residentialDetails ?? {};

    String getVal(dynamic val) {
      if (val == null) return '';
      final str = val.toString().trim();
      return (str == 'null' || str == '0' || str == '') ? '' : str;
    }

    final bhk = getVal(p.bhk ?? res['bhk']);
    if (bhk.isNotEmpty) rows.add(_buildTermsRow('BHK', bhk, context));

    final bed = getVal(p.bedrooms ?? res['bedrooms']);
    if (bed.isNotEmpty) rows.add(_buildTermsRow('Bedrooms', bed, context));

    final bath = getVal(p.bathrooms ?? res['bathrooms']);
    if (bath.isNotEmpty) rows.add(_buildTermsRow('Bathrooms', bath, context));

    final balc = getVal(p.balconies ?? res['balconies']);
    if (balc.isNotEmpty) rows.add(_buildTermsRow('Balconies', balc, context));

    final park = getVal(res['parking']);
    if (park.isNotEmpty) rows.add(_buildTermsRow('Parking', park, context));

    final floor = getVal(res['floor']);
    if (floor.isNotEmpty) rows.add(_buildTermsRow('Floor No.', floor, context));

    final tFloor = getVal(res['total_floors']);
    if (tFloor.isNotEmpty)
      rows.add(_buildTermsRow('Total Floors', tFloor, context));

    final age = getVal(res['property_age']);
    if (age.isNotEmpty) {
      final formattedAge = age
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      rows.add(_buildTermsRow('Property Age', formattedAge, context));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: rows),
        ],
      ),
    );
  }

  Widget _buildPricingDetails(
    BuildContext context,
    Property p,
    String displayPrice,
  ) {
    final List<Widget> rows = [];

    rows.add(_buildTermsRow('Property Price', displayPrice, context));

    if (p.priceNegotiable == true) {
      rows.add(_buildTermsRow('Negotiable', 'Yes', context));
    }

    if (p.bookingAmount != null && p.bookingAmount! > 0) {
      rows.add(
        _buildTermsRow('Booking Amount', '₹${p.bookingAmount}', context),
      );
    }

    final res = p.residentialDetails ?? {};
    final mCharges =
        res['maintenance_charges']?.toString() ??
        res['maintenance_charge']?.toString();
    if (mCharges != null &&
        mCharges.trim().isNotEmpty &&
        mCharges != '0' &&
        mCharges != 'null') {
      rows.add(_buildTermsRow('Maintenance', '₹$mCharges / month', context));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: rows),
        ],
      ),
    );
  }

  Widget _buildRelatedProperties(BuildContext context, Property currentProp) {
    final propertyState = ref.watch(propertyNotifierProvider);
    final allProperties = propertyState.all;

    final related = allProperties
        .where((p) => p.id != currentProp.id && p.type == currentProp.type)
        .take(6)
        .toList();

    if (related.isEmpty) {
      final fallbackRelated = allProperties
          .where((p) => p.id != currentProp.id)
          .take(6)
          .toList();
      if (fallbackRelated.isEmpty) return const SizedBox.shrink();
      related.addAll(fallbackRelated);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F7)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Related Properties',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final prop = related[index];
              return RelatedPropertyCard(
                property: prop,
                onTap: () {
                  context.push('/property/${prop.id}', extra: prop);
                },
              );
            },
          ),
        ),
      ],
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
              String bhkPrefix = '';
              if (p.bhk != null && p.bhk! > 0) {
                bhkPrefix = '${p.bhk} BHK ';
              } else if (p.bedrooms != null && p.bedrooms! > 0) {
                bhkPrefix = '${p.bedrooms} BHK ';
              } else {
                final bhkMatch = RegExp(r'(\d+)\s*(BHK|Bed|Bedroom|BH|B)', caseSensitive: false).firstMatch(p.name + p.description);
                if (bhkMatch != null) {
                  bhkPrefix = '${int.tryParse(bhkMatch.group(1) ?? '') ?? ''} BHK ';
                }
              }
              return '$bhkPrefix$type in $cleanLocality';
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
                      property: p,
                      specs: specs,
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
                          String bhkPrefix = '';
                          if (p.bhk != null && p.bhk! > 0) {
                            bhkPrefix = '${p.bhk} BHK ';
                          } else if (p.bedrooms != null && p.bedrooms! > 0) {
                            bhkPrefix = '${p.bedrooms} BHK ';
                          } else {
                            final bhkMatch = RegExp(
                              r'(\d+)\s*(BHK|Bed|Bedroom|BH|B)',
                              caseSensitive: false,
                            ).firstMatch(p.name + p.description);
                            if (bhkMatch != null) {
                              bhkPrefix =
                                  '${int.tryParse(bhkMatch.group(1) ?? '') ?? ''} BHK ';
                            }
                          }
                          return '$bhkPrefix$type in $cleanLocality';
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
                    if (p.furnishingsList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Furnishings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ResponsiveItemGrid<String>(
                              items: p.furnishingsList,
                              fixedColumns: 3,
                              spacing: 8,
                              runSpacing: 8,
                              isCollapsible: true,
                              isExpanded: _isFurnishingsExpanded,
                              onToggle: () {
                                setState(() {
                                  _isFurnishingsExpanded =
                                      !_isFurnishingsExpanded;
                                });
                              },
                              itemBuilder: (context, a) {
                                final formatted = a
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
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFEAECF0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF5C46E8),
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
                      const SizedBox(height: 20),
                    ],

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
                    _buildPricingDetails(context, p, displayPrice),
                    _buildExtraDetails(context, p),
                    _buildAreaDetails(context, p),
                    _buildAdditionalRooms(p),
                    _buildPropertyDetails(context, p),
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

                    _buildRelatedProperties(context, p),

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
                                child: const Text(
                                  'Call Agent',
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
  final Property property;
  final PropertySpecs specs;

  const _HeroMediaLight({
    required this.videos,
    required this.images,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
    required this.isFavorited,
    required this.isLoading,
    required this.property,
    required this.specs,
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

          Positioned(
            bottom: 12,
            left: 12,
            right: 80, // Leave space for the "1/X" counter on the right
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (widget.property.type.toLowerCase() == 'sale')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FDF0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'For Sale',
                      style: TextStyle(
                        color: Color(0xFF039855),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (widget.property.type.toLowerCase() == 'rent')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'For Rent',
                      style: TextStyle(
                        color: Color(0xFF0055FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (widget.property.type.toLowerCase() == 'pg')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PG / Co-Living',
                      style: TextStyle(
                        color: Color(0xFF6941C6),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                if (widget.property.categoryName != null &&
                    widget.property.categoryName!.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.property.categoryName!.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
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
    final media = widget.mediaList.isEmpty
        ? const [
            {'type': 'image', 'url': ''},
          ]
        : widget.mediaList;
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
