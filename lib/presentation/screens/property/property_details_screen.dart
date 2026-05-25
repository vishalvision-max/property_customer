import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/autoplay_video_preview.dart';
import '../../widgets/zoomable_video_page.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  Future<Property>? _future;

  static const _kPrimary = Color(0xff7C5CFF);
  static const _kCard = Colors.white;
  static const _kTextDark = Color(0xff111827);
  static const _kTextMid = Color(0xff6B7280);
  static const _kBorder = Color(0xffE5E7EB);
  static const _kFallbackImage =
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    _future = Future<Property>.microtask(
      () => ref.read(propertyProvider.notifier).fetchDetails(widget.propertyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cached = ref
        .watch(propertyProvider.notifier)
        .getById(widget.propertyId);

    return FutureBuilder<Property>(
      future: _future,
      initialData: cached,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthed = ref.watch(authProvider).user != null;
        final isFav = ref.watch(
          favoritesProvider.select((s) => s.contains(p.id)),
        );
        final fmt = DateFormat('MMM d, yyyy');

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

        void contactAgent() {
          if (!isAuthed) {
            AppSnackbar.showError(context, 'Please login to contact');
            context.push('/login?from=${Uri.encodeComponent('/leads/new?property_id=${p.id}&type=${p.type}')}');
            return;
          }
          context.push('/leads/new?property_id=${p.id}&type=${p.type}');
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _HeroMediaLight(
                      videos: p.videos,
                      images: p.images,
                      title: p.name,
                      tagLabel: p.type == 'rent' ? 'For Rent' : 'For Buy',
                      onBack: () => context.pop(),
                      onShare: () => AppSnackbar.showError(
                        context,
                        'Share not implemented yet',
                      ),
                      onToggleFavorite: toggleFavorite,
                      isFavorited: isFav,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: _kTextDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: _kPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  p.location,
                                  style: const TextStyle(
                                    color: _kTextMid,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _PriceCardLight(type: p.type, price: p.price),
                          const SizedBox(height: 16),
                          _sectionTitleLight('Amenities', ''),
                          const SizedBox(height: 14),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                            children: p.amenities.isEmpty
                                ? const [
                                    _AmenityCardLight(
                                      icon: Icons.check_circle_outline,
                                      title: 'N/A',
                                    ),
                                  ]
                                : [
                                    for (final a in p.amenities.take(6))
                                      _AmenityCardLight(
                                        icon: _amenityToIcon(a),
                                        title: a,
                                      ),
                                  ],
                          ),
                          const SizedBox(height: 24),
                          _sectionTitleLight('Description', ''),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Text(
                              p.description.isEmpty
                                  ? 'No description provided.'
                                  : p.description,
                              style: const TextStyle(
                                color: _kTextMid,
                                height: 1.8,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _sectionTitleLight('Availability', ''),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: _kPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AVAILABLE FROM',
                                        style: TextStyle(
                                          color: _kTextMid,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fmt.format(p.availability),
                                        style: const TextStyle(
                                          color: _kTextDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: scheduleVisit,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: _kPrimary.withValues(alpha: 0.10),
                                    ),
                                    child: const Text(
                                      'Schedule',
                                      style: TextStyle(
                                        color: _kPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: theme.bottomAppBarTheme.color ?? scheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: scheme.outline.withValues(
                            alpha: isDark ? 0.30 : 0.15,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: contactAgent,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.primary.withValues(
                                    alpha: isDark ? 0.55 : 0.40,
                                  ),
                                  width: 1.5,
                                ),
                                color: scheme.primary.withValues(
                                  alpha: isDark ? 0.18 : 0.06,
                                ),
                              ),
                              child: const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone, color: _kPrimary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Contact Agent',
                                        style: TextStyle(
                                          color: _kPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: scheduleVisit,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _kPrimary,
                              ),
                              child: const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Schedule Visit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
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

  static IconData _amenityToIcon(String a) {
    final s = a.toLowerCase();
    if (s.contains('water')) return Icons.water_drop;
    if (s.contains('electric')) return Icons.bolt;
    if (s.contains('park')) return Icons.local_parking;
    if (s.contains('security')) return Icons.security;
    if (s.contains('wifi')) return Icons.wifi;
    if (s.contains('gym')) return Icons.fitness_center;
    return Icons.check_circle_outline;
  }
}

class _HeroMediaLight extends StatefulWidget {
  final List<String> videos;
  final List<String> images;
  final String title;
  final String tagLabel;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;

  const _HeroMediaLight({
    required this.videos,
    required this.images,
    required this.title,
    required this.tagLabel,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
    required this.isFavorited,
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

    String fallbackImage() {
      final first = images.isNotEmpty ? images.first.trim() : '';
      return first.isEmpty
          ? _PropertyDetailsScreenState._kFallbackImage
          : first;
    }

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(76),
                ),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1,
                    enableInfiniteScroll: total > 1,
                    onPageChanged: (i, _) => setState(() => _index = i),
                  ),
                  items: [
                    for (final v in videos)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ZoomableVideoPage(url: v),
                          ),
                        ),
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
                            placeholder: (context, url) =>
                                Container(color: Colors.black12),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.photo, size: 36),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 0; i < images.length; i++)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ZoomGallery(
                              images: images,
                              initialIndex: i,
                              title: widget.title,
                            ),
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: images[i].trim().isEmpty
                              ? _PropertyDetailsScreenState._kFallbackImage
                              : images[i].trim(),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              Container(color: Colors.black12),
                          errorWidget: (context, url, error) =>
                              CachedNetworkImage(
                            imageUrl: _PropertyDetailsScreenState._kFallbackImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtnLight(
                  icon: Icons.arrow_back_ios_new,
                  onTap: widget.onBack,
                ),
                Row(
                  children: [
                    _CircleBtnLight(
                      icon: Icons.share_outlined,
                      onTap: widget.onShare,
                    ),
                    const SizedBox(width: 10),
                    _CircleBtnLight(
                      icon: widget.isFavorited
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      onTap: widget.onToggleFavorite,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.tagLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (total > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

class _HeroGalleryLight extends StatefulWidget {
  final List<String> images;
  final String title;
  final String tagLabel;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;

  const _HeroGalleryLight({
    required this.images,
    required this.title,
    required this.tagLabel,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
    required this.isFavorited,
  });

  @override
  State<_HeroGalleryLight> createState() => _HeroGalleryLightState();
}

class _HeroGalleryLightState extends State<_HeroGalleryLight> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? const <String>[''] : widget.images;

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  // topRight: Radius.circular(26),
                  bottomRight: Radius.circular(76),
                ),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1,
                    enableInfiniteScroll: images.length > 1,
                    onPageChanged: (i, _) => setState(() => _index = i),
                  ),
                  items: images.map((url) {
                    final resolved = url.trim().isEmpty
                        ? _PropertyDetailsScreenState._kFallbackImage
                        : url.trim();
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ZoomGallery(
                            images: images,
                            initialIndex: _index,
                            title: widget.title,
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: resolved,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            Container(color: Colors.black12),
                        errorWidget: (context, url, error) =>
                            CachedNetworkImage(
                          imageUrl: _PropertyDetailsScreenState._kFallbackImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtnLight(
                  icon: Icons.arrow_back_ios_new,
                  onTap: widget.onBack,
                ),
                Row(
                  children: [
                    _CircleBtnLight(
                      icon: Icons.share_outlined,
                      onTap: widget.onShare,
                    ),
                    const SizedBox(width: 10),
                    _CircleBtnLight(
                      icon: widget.isFavorited
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      onTap: widget.onToggleFavorite,
                      bgColor: widget.isFavorited
                          ? _PropertyDetailsScreenState._kPrimary
                          : Colors.white70,
                      iconColor: widget.isFavorited
                          ? Colors.white
                          : _PropertyDetailsScreenState._kPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length.clamp(1, 7),
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? _PropertyDetailsScreenState._kPrimary
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _PropertyDetailsScreenState._kBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo,
                    color: _PropertyDetailsScreenState._kTextMid,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_index + 1} / ${images.length}',
                    style: const TextStyle(
                      color: _PropertyDetailsScreenState._kTextMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtnLight extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;

  const _CircleBtnLight({
    required this.icon,
    required this.onTap,
    this.bgColor = Colors.white70,
    this.iconColor = _PropertyDetailsScreenState._kTextDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: _PropertyDetailsScreenState._kBorder),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

Widget _sectionTitleLight(String title, String action) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _PropertyDetailsScreenState._kTextDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      if (action.isNotEmpty)
        Text(
          action,
          style: const TextStyle(
            color: _PropertyDetailsScreenState._kPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

class _AmenityCardLight extends StatelessWidget {
  final IconData icon;
  final String title;

  const _AmenityCardLight({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PropertyDetailsScreenState._kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PropertyDetailsScreenState._kBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _PropertyDetailsScreenState._kPrimary, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PropertyDetailsScreenState._kTextMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCardLight extends StatelessWidget {
  final String type;
  final int price;

  const _PriceCardLight({required this.type, required this.price});

  @override
  Widget build(BuildContext context) {
    final label = type == 'rent' ? 'MONTHLY RENT' : 'PRICE';
    final value = type == 'rent' ? '\$$price /mo' : '\$$price';
    final chip = type == 'rent' ? 'Rent' : 'Buy';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _PropertyDetailsScreenState._kPrimary.withValues(alpha: 0.18),
        ),
        gradient: LinearGradient(
          colors: [
            _PropertyDetailsScreenState._kPrimary.withValues(alpha: 0.10),
            const Color(0xffffffff),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PropertyDetailsScreenState._kTextMid,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: _PropertyDetailsScreenState._kTextDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _PropertyDetailsScreenState._kPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text(
                  chip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
  final List<String> images;
  final int initialIndex;
  final String title;

  const _ZoomGallery({
    required this.images,
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
    final maxIdx = (widget.images.length - 1).clamp(0, 999999);
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
    final images = widget.images.isEmpty ? const <String>[''] : widget.images;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final url = images[i].trim().isEmpty
              ? _PropertyDetailsScreenState._kFallbackImage
              : images[i].trim();
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: _PropertyDetailsScreenState._kFallbackImage,
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
