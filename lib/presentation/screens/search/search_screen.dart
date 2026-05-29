import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/filters/common_filter_provider.dart';
import '../../../data/models/property.dart';
import '../../../data/services/property_service.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/primary_button.dart';
import 'search_args.dart';

// Keep styling close to HomeScreen design tokens
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const String _kHeroImageUrl =
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=900&q=85';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _location = TextEditingController();
  Future<List<Property>>? _resultsFuture;
  Timer? _debounce;

  static const _amenityOptions = [
    'Water',
    'Electricity',
    'Parking',
    'Security',
  ];
  static const _propertyTypes = [
    'Any',
    'Apartments',
    'Independent House',
    'Builder Floor',
    'Plot',
    'Studio',
    'Duplex',
    'Villa',
  ];
  static const Map<String, String> _sortOptions = {
    '': 'Relevance',
    'price_low_to_high': 'Price: Low → High',
    'price_high_to_low': 'Price: High → Low',
    'newest': 'Newest',
  };

  @override
  void initState() {
    super.initState();
    // Initialize controller with current filter searchText if any
    final initialText = ref.read(commonFilterNotifierProvider).searchText;
    _location.text = initialText;

    // Set initial values if they are default to match search screen expected defaults
    final currentFilters = ref.read(commonFilterNotifierProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentFilters.listingType == 'Any') {
        ref.read(commonFilterNotifierProvider.notifier).updateListingType('rent');
      }
      if (currentFilters.priceRange == null) {
        final mode = currentFilters.listingType == 'Any' ? 'rent' : currentFilters.listingType;
        final defaultRange = mode == 'rent'
            ? const RangeValues(5000, 50000)
            : const RangeValues(1000000, 8000000);
        ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(defaultRange);
      }
      _scheduleSearch();
    });

    _location.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _location.removeListener(_onLocationChanged);
    _location.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    ref.read(commonFilterNotifierProvider.notifier).updateSearchText(_location.text.trim());
    _scheduleSearch();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final filters = ref.read(commonFilterNotifierProvider);
      final isRent = (filters.listingType == 'Any' ? 'rent' : filters.listingType) == 'rent';
      final defStart = isRent ? 5000.0 : 1000000.0;
      final defEnd = isRent ? 50000.0 : 8000000.0;
      setState(() {
        _resultsFuture = ref
            .read(propertyNotifierProvider.notifier)
            .search(
              mode: filters.listingType == 'Any' ? 'rent' : filters.listingType,
              budgetRange: BudgetRange(
                filters.priceRange?.start ?? defStart,
                filters.priceRange?.end ?? defEnd,
              ),
              propertyType: filters.propertyType,
              amenities: filters.amenities,
              locationQuery: filters.searchText,
              sortBy: filters.sortBy,
            );
      });
    });
  }

  bool get _hasAtLeastOneFilter {
    final filters = ref.read(commonFilterNotifierProvider);
    final isRent = (filters.listingType == 'Any' ? 'rent' : filters.listingType) == 'rent';
    final defStart = isRent ? 5000.0 : 1000000.0;
    final defEnd = isRent ? 50000.0 : 8000000.0;
    final budgetChanged = filters.priceRange != null &&
        (filters.priceRange!.start != defStart || filters.priceRange!.end != defEnd);
    final typeChanged = filters.propertyType != 'Any';
    final amenChanged = filters.amenities.isNotEmpty;
    final locChanged = filters.searchText.isNotEmpty;
    final sortChanged = filters.sortBy.isNotEmpty;
    return budgetChanged || typeChanged || amenChanged || locChanged || sortChanged;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = ref.watch(commonFilterNotifierProvider);
    final currentMode = filters.listingType == 'Any' ? 'rent' : filters.listingType;

    // Limits
    final double minLimit = 0;
    final double maxLimit = currentMode == 'rent' ? 100000 : 10000000;

    // Sensible defaults if priceRange is null
    final defaultRange = currentMode == 'rent'
        ? const RangeValues(5000, 50000)
        : const RangeValues(1000000, 8000000);

    final currentBudget = filters.priceRange ?? defaultRange;

    // Safe clamp to avoid RangeSlider assertion crashes
    final double startVal = currentBudget.start.clamp(minLimit, maxLimit);
    final double endVal = currentBudget.end.clamp(startVal, maxLimit);
    final safeBudget = RangeValues(startVal, endVal);

    final String effectivePropertyType = _propertyTypes.contains(filters.propertyType)
        ? filters.propertyType
        : 'Any';

    String formatPrice(double val) {
      if (val >= 10000000) {
        return '₹${(val / 10000000).toStringAsFixed(1)} Cr';
      } else if (val >= 100000) {
        return '₹${(val / 100000).toStringAsFixed(0)} Lakh';
      }
      return '₹${val.toInt()}';
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 20,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w900, color: _kTextDark),
            ),
            actions: [
              if (_hasAtLeastOneFilter)
                TextButton(
                  onPressed: () {
                    ref.read(commonFilterNotifierProvider.notifier).resetFilters();
                    ref.read(commonFilterNotifierProvider.notifier).updateListingType('rent');
                    ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(const RangeValues(5000, 50000));
                    _location.clear();
                    _scheduleSearch();
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),
          SliverToBoxAdapter(
            child: ClipRRect(
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: _kHeroImageUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.6, 0.0),
                      placeholder: (context, url) => Container(
                        color: _kPrimary.withValues(alpha: 0.15),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: _kPrimary.withValues(alpha: 0.35),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.55, 1.0],
                          colors: [
                            Color(0xEE1E1E1E),
                            Color(0x77222222),
                            Color(0x00222222),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: TextField(
                        controller: _location,
                        decoration: InputDecoration(
                          hintText: 'Search location…',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.place_outlined),
                          suffixIcon: _location.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _location.clear();
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SegmentChip(
                                label: 'Rent',
                                selected: currentMode == 'rent',
                                onTap: () {
                                  ref.read(commonFilterNotifierProvider.notifier).updateListingType('rent');
                                  ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(const RangeValues(5000, 50000));
                                  _scheduleSearch();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SegmentChip(
                                label: 'Buy',
                                selected: currentMode == 'buy',
                                onTap: () {
                                  ref.read(commonFilterNotifierProvider.notifier).updateListingType('buy');
                                  ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(const RangeValues(1000000, 8000000));
                                  _scheduleSearch();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Budget',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _kTextDark,
                                ),
                              ),
                            ),
                            Text(
                              currentMode == 'rent'
                                  ? '${formatPrice(safeBudget.start)} - ${formatPrice(safeBudget.end)}/mo'
                                  : '${formatPrice(safeBudget.start)} - ${formatPrice(safeBudget.end)}',
                              style: const TextStyle(
                                color: _kTextMid,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: safeBudget,
                          min: minLimit,
                          max: maxLimit,
                          divisions: 100,
                          activeColor: _kPrimary,
                          onChanged: (v) {
                            ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(v);
                            _scheduleSearch();
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: effectivePropertyType,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.home_work_outlined),
                            labelText: 'Property type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _propertyTypes
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) {
                            ref.read(commonFilterNotifierProvider.notifier).updatePropertyType(v ?? 'Any');
                            _scheduleSearch();
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: filters.sortBy,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.sort_rounded),
                            labelText: 'Sort by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _sortOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            ref.read(commonFilterNotifierProvider.notifier).updateSort(v ?? '', 'asc');
                            _scheduleSearch();
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final a in _amenityOptions)
                              FilterChip(
                                label: Text(a),
                                selected: filters.amenities.contains(a),
                                selectedColor: _kPrimary.withValues(
                                  alpha: 0.15,
                                ),
                                checkmarkColor: _kPrimary,
                                side: BorderSide(
                                  color: filters.amenities.contains(a)
                                      ? _kPrimary.withValues(alpha: 0.35)
                                      : _kBorder,
                                ),
                                labelStyle: TextStyle(
                                  color: filters.amenities.contains(a)
                                      ? _kPrimary
                                      : _kTextDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (s) {
                                  final nextAmenities = List<String>.from(filters.amenities);
                                  if (s) {
                                    nextAmenities.add(a);
                                  } else {
                                    nextAmenities.remove(a);
                                  }
                                  ref.read(commonFilterNotifierProvider.notifier).updateAmenities(nextAmenities);
                                  _scheduleSearch();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Search',
                          onPressed: _hasAtLeastOneFilter
                              ? () {
                                  context.push(
                                    '/properties',
                                    extra: SearchArgs(
                                      mode: currentMode,
                                      budget: safeBudget,
                                      propertyType: effectivePropertyType,
                                      amenities: filters.amenities,
                                      locationQuery: filters.searchText,
                                      sortBy: filters.sortBy,
                                    ),
                                  );
                                }
                              : null,
                          leading: const Icon(Icons.search_rounded),
                        ),
                        if (!_hasAtLeastOneFilter) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Select at least one filter to enable search.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Property>>(
                    future: _resultsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 260,
                          child: ShimmerList(),
                        );
                      }
                      final items = snap.data ?? const <Property>[];
                      if (items.isEmpty) {
                        return Text(
                          'No properties found.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        );
                      }
                      final shown = items.take(6).toList(growable: false);
                      return Column(
                        children: [
                          for (final p in shown) ...[
                            PropertyCard(
                              property: p,
                              onTap: () => context.push('/property/${p.id}'),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _kPrimary : _kBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _kTextDark,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
