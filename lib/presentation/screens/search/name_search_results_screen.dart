import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../property/property_name_search_args.dart';

// New Premium filter components
import '../../widgets/filter_chip.dart';
import '../../sheets/filter_bottom_sheet.dart';
import '../../sheets/budget_bottom_sheet.dart';
import '../../sheets/property_type_bottom_sheet.dart';
import '../../providers/property_filter_provider.dart';
import '../../../data/models/property_filter_model.dart';

// Category tab provider
final searchCategoryTabProvider = StateProvider<String>((ref) => 'All');

class NameSearchResultsScreen extends ConsumerStatefulWidget {
  final PropertyNameSearchArgs args;

  const NameSearchResultsScreen({super.key, required this.args});

  @override
  ConsumerState<NameSearchResultsScreen> createState() =>
      _NameSearchResultsScreenState();
}

class _NameSearchResultsScreenState
    extends ConsumerState<NameSearchResultsScreen> {
  List<Property>? _baseItems;
  final TextEditingController _searchController = TextEditingController();
  late String _currentQuery;

  // ── Sort ─────────────────────────────────────────────────────────────────
  // 0 = Relevance, 1 = Price Low→High, 2 = Price High→Low
  int _sortOrder = 0;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  static const _kPrimary = Color(0xFF7B2FF7);
  static const _kBg = Color(0xFFF6F7FB);
  static const _kTextDark = Color(0xFF1A1A2E);
  static const _kTextMid = Color(0xFF6B7280);
  static const _kBorder = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.args.query;
    // Defer provider mutations to after the first frame to avoid
    // "Tried to modify a provider while the widget tree was building" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBaseItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _parseQueryAndGetKeyword(String query) {
    // Replace commas with spaces first
    final clean = query.replaceAll(',', ' ').trim();
    final words = clean
        .split(RegExp(r'\s+'))
        .map((w) => w.toLowerCase())
        .toList();

    String? matchedIntent;
    final matchedBhk = <String>[];
    final matchedTypes = <String>[];
    final locationWords = <String>[];

    // Clear previous filters to start fresh
    ref.read(propertyFilterProvider.notifier).clearFilters();

    int i = 0;
    while (i < words.length) {
      final word = words[i];

      // Check for intent
      if (word == 'rent') {
        matchedIntent = 'Rent';
        i++;
        continue;
      }
      if (word == 'buy' || word == 'sale') {
        matchedIntent = 'Buy';
        i++;
        continue;
      }
      if (word == 'commercial') {
        matchedIntent = 'Commercial';
        i++;
        continue;
      }

      // Check for BHK: e.g. "1bhk", "1 bhk", "bhk"
      if (word.contains('bhk')) {
        // If it's just "bhk", check if previous word was a number
        final digits = RegExp(r'\d').firstMatch(word)?.group(0);
        if (digits != null) {
          matchedBhk.add('$digits BHK');
        } else if (i > 0 && RegExp(r'^\d+$').hasMatch(words[i - 1])) {
          matchedBhk.add('${words[i - 1]} BHK');
          if (locationWords.isNotEmpty && locationWords.last == words[i - 1]) {
            locationWords.removeLast();
          }
        }
        i++;
        continue;
      }

      // If this word is a single digit and the next word is "bhk"
      if (RegExp(r'^\d+$').hasMatch(word) &&
          i + 1 < words.length &&
          words[i + 1].contains('bhk')) {
        matchedBhk.add('$word BHK');
        i += 2;
        continue;
      }

      // Check for property types
      if (word == 'flat' ||
          word == 'apartment' ||
          word == 'flats' ||
          word == 'apartments') {
        matchedTypes.add('Apartment');
        i++;
        continue;
      }
      if (word == 'villa' || word == 'house' || word == 'villas') {
        matchedTypes.add('Villa');
        i++;
        continue;
      }
      if (word == 'plot' || word == 'land' || word == 'plots') {
        matchedTypes.add('Plot');
        i++;
        continue;
      }
      if (word == 'office' || word == 'shop' || word == 'shops') {
        matchedTypes.add('Office');
        i++;
        continue;
      }

      // Stopwords to ignore
      if (word == 'in' ||
          word == 'at' ||
          word == 'for' ||
          word == 'under' ||
          word == 'any' ||
          word == 'price' ||
          word == 'lakh' ||
          word == 'cr') {
        i++;
        continue;
      }

      // Otherwise, keep it as location word
      locationWords.add(word);
      i++;
    }

    // Only set intent from the parsed query or the args mode when we
    // actually need it for filtering. Leave it empty to show all types.
    if (matchedIntent != null) {
      ref.read(propertyFilterProvider.notifier).updateIntent(matchedIntent);
    }
    // NOTE: We intentionally do NOT fall back to widget.args.mode here.
    // An empty intent means "show all property types" in _getFilteredItems.

    for (final bhk in matchedBhk) {
      ref.read(propertyFilterProvider.notifier).toggleBhk(bhk);
    }
    for (final type in matchedTypes) {
      ref.read(propertyFilterProvider.notifier).togglePropertyType(type);
    }

    if (locationWords.isEmpty) {
      // No location keyword found — pass empty string so the API
      // returns all properties (fetchAll behaviour) instead of
      // doing a literal search on the raw composite query string.
      return '';
    }

    final resolvedKeyword = locationWords
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    ref.read(propertyFilterProvider.notifier).updateCity(resolvedKeyword);
    return resolvedKeyword;
  }

  Future<void> _loadBaseItems() async {
    final searchKeyword = _parseQueryAndGetKeyword(_currentQuery);
    _searchController.text = searchKeyword;

    // Fetch matched properties from API using the resolved city keyword.
    // An empty keyword means fetch all properties (no keyword filter).
    try {
      final items = await ref
          .read(propertyNotifierProvider.notifier)
          .searchByName(mode: widget.args.mode, query: searchKeyword);
      if (mounted) {
        setState(() => _baseItems = items);
      }
    } catch (e, st) {
      debugPrint('[NameSearchResults] searchByName error: $e\n$st');
      if (mounted) {
        setState(() => _baseItems = []);
      }
    }
  }

  void _openFilterBottomSheet() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterBottomSheet(properties: _baseItems),
    );
    if (applied == true && mounted) {
      setState(() {});
    }
  }

  void _openBudgetBottomSheet() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const BudgetBottomSheet(),
    );
    if (applied == true && mounted) {
      setState(() {});
    }
  }

  void _openPropertyTypeBottomSheet() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PropertyTypeBottomSheet(),
    );
    if (applied == true && mounted) {
      setState(() {});
    }
  }

  // ── Sort labels ──────────────────────────────────────────────────────────
  static const _sortLabels = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
  ];

  void _showSortDialog() {
    showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_sortLabels.length, (i) {
              final isSelected = i == _sortOrder;
              return ListTile(
                title: Text(
                  _sortLabels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? _kPrimary : _kTextDark,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: _kPrimary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx, i);
                },
              );
            }),
          ),
        ),
      ),
    ).then((selected) {
      if (selected != null && selected != _sortOrder && mounted) {
        setState(() {
          _sortOrder = selected;
          _visibleCount = _pageSize; // reset to page 1 on sort change
        });
      }
    });
  }

  /// Returns filtered + sorted list.
  List<Property> _getFilteredItems(
    PropertyFilterState filters,
    String category,
  ) {
    final base = _baseItems ?? [];
    final filtered = base.where((p) {
      // 1. Intent Match — empty intent means 'show all' (no filter applied)
      if (filters.selectedIntent.isNotEmpty) {
        if (filters.selectedIntent == 'Buy' &&
            p.type != 'buy' &&
            p.type != 'sale')
          return false;
        if (filters.selectedIntent == 'Rent' && p.type != 'rent') return false;
        if (filters.selectedIntent == 'Commercial' &&
            !p.propertyKind.toLowerCase().contains('commercial') &&
            !p.name.toLowerCase().contains('office')) {
          return false;
        }
      }

      // 2. Localities Match
      if (filters.selectedLocalities.isNotEmpty) {
        bool localityMatch = false;
        for (final loc in filters.selectedLocalities) {
          if (p.location.toLowerCase().contains(loc.toLowerCase())) {
            localityMatch = true;
            break;
          }
        }
        if (!localityMatch) return false;
      }

      // 3. BHK Type Match (digit comparison fallback for null/empty titles)
      if (filters.selectedBhk.isNotEmpty) {
        bool bhkMatch = false;
        for (final bhk in filters.selectedBhk) {
          final bhkClean = bhk.toLowerCase().replaceAll(' ', '');
          final nameClean = p.name.toLowerCase().replaceAll(' ', '');
          final kindClean = p.propertyKind.toLowerCase().replaceAll(' ', '');

          final digitMatch = RegExp(r'\d').firstMatch(bhk)?.group(0);
          final digit = digitMatch != null ? int.tryParse(digitMatch) : null;

          if (digit != null && p.bhk == digit) {
            bhkMatch = true;
            break;
          }
          if (nameClean.contains(bhkClean) || kindClean.contains(bhkClean)) {
            bhkMatch = true;
            break;
          }
        }
        if (!bhkMatch) return false;
      }

      // 4. Property Type Match
      if (filters.selectedPropertyTypes.isNotEmpty) {
        bool typeMatch = false;
        for (final type in filters.selectedPropertyTypes) {
          if (p.propertyKind.toLowerCase().contains(type.toLowerCase()) ||
              p.name.toLowerCase().contains(type.toLowerCase())) {
            typeMatch = true;
            break;
          }
        }
        if (!typeMatch) return false;
      }

      // 5. Category Tab Match
      if (category == 'New Launches' &&
          !p.description.toLowerCase().contains('launch'))
        return false;
      if (category == 'Owner' && !p.description.toLowerCase().contains('owner'))
        return false;
      if (category == 'Top Picks' && p.amenities.length < 3) return false;
      if (category == 'Ready to Move' &&
          !p.description.toLowerCase().contains('ready'))
        return false;
      if (category == 'Verified' &&
          !p.description.toLowerCase().contains('verified'))
        return false;

      // 6. Budget Match
      final priceCr = p.price / 10000000.0;
      if (priceCr < filters.minBudget ||
          (filters.maxBudget < 20.0 && priceCr > filters.maxBudget)) {
        return false;
      }

      return true;
    }).toList();

    // ── Apply sort order ───────────────────────────────────────────────────
    if (_sortOrder == 1) {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOrder == 2) {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    // _sortOrder == 0 → Relevance (original API order, no sort)

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(propertyFilterProvider);
    final notifier = ref.read(propertyFilterProvider.notifier);
    final category = ref.watch(searchCategoryTabProvider);

    final filteredList = _getFilteredItems(filters, category);
    final activeFilterCount = notifier.getActiveFilterCount();
    // Clamp visible count to total available
    final visibleList = filteredList.take(_visibleCount).toList();
    final hasMore = _visibleCount < filteredList.length;

    if (_searchController.text != filters.selectedCity &&
        filters.selectedCity.isNotEmpty) {
      _searchController.text = filters.selectedCity;
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar Section
            _buildTopSearchBar(filters, notifier),

            // Category Tab Section
            // _buildCategoryTabs(category),

            // Sticky Filter Chips Row
            _buildFilterChipsRow(filters, notifier, activeFilterCount),

            // Applied Filters Chips Row (Inline)
            _buildAppliedFilterChips(filters, notifier),

            // Results count banner
            _buildResultsHeader(filteredList.length),

            // Results list or loader
            Expanded(
              child: _baseItems == null
                  ? const ShimmerList()
                  : _buildResultsList(visibleList, filteredList.length, hasMore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSearchBar(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _kTextDark,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                      onSubmitted: (val) {
                        setState(() {
                          _currentQuery = val;
                          _baseItems = null; // display shimmer
                        });
                        notifier.updateCity(val);
                        _loadBaseItems();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search sectors/areas...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: _kTextMid,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: _kTextMid),
                    onPressed: () {
                      final val = _searchController.text;
                      setState(() {
                        _currentQuery = val;
                        _baseItems = null;
                      });
                      notifier.updateCity(val);
                      _loadBaseItems();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(String activeTab) {
    final categories = [
      {'name': 'All', 'icon': Icons.home_work_rounded},
      {'name': 'New Launches', 'icon': Icons.rocket_launch_rounded},
      {'name': 'Owner', 'icon': Icons.person_pin_rounded},
      {'name': 'Top Picks', 'icon': Icons.star_rounded},
      {'name': 'Ready to Move', 'icon': Icons.vpn_key_rounded},
      {'name': 'Verified', 'icon': Icons.verified_user_rounded},
    ];

    return Container(
      color: Colors.white,
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final name = cat['name'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = activeTab == name;

          return GestureDetector(
            onTap: () {
              ref.read(searchCategoryTabProvider.notifier).state = name;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? _kPrimary : _kTextMid,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? _kPrimary : _kTextMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2.5,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChipsRow(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
    int activeFilterCount,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            CustomFilterChip(
              label: '',
              isSelected: false,
              leading: const Icon(Icons.swap_vert, size: 20, color: _kTextDark),
              onTap: _showSortDialog,
            ),
            const SizedBox(width: 8),
            CustomFilterChip(
              label: activeFilterCount > 0
                  ? 'Filters ($activeFilterCount)'
                  : 'Filters',
              isSelected: activeFilterCount > 0,
              onTap: _openFilterBottomSheet,
            ),
            const SizedBox(width: 8),
            CustomFilterChip(
              label: 'Budget',
              isSelected: filters.minBudget > 0.0 || filters.maxBudget < 20.0,
              onTap: _openBudgetBottomSheet,
            ),
            const SizedBox(width: 8),
            CustomFilterChip(
              label: '2 BHK',
              isSelected: filters.selectedBhk.contains('2 BHK'),
              onTap: () {
                notifier.toggleBhk('2 BHK');
              },
            ),
            const SizedBox(width: 8),
            CustomFilterChip(
              label: 'Property Type',
              isSelected: filters.selectedPropertyTypes.isNotEmpty,
              onTap: _openPropertyTypeBottomSheet,
            ),
            const SizedBox(width: 8),
            CustomFilterChip(
              label: 'Reset',
              isSelected: false,
              leading: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: _kTextMid,
              ),
              onTap: () {
                notifier.clearFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedFilterChips(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    final chips = <Widget>[];

    for (final loc in filters.selectedLocalities) {
      chips.add(_appliedChip(loc, () => notifier.removeLocality(loc)));
    }
    for (final bhk in filters.selectedBhk) {
      chips.add(_appliedChip(bhk, () => notifier.toggleBhk(bhk)));
    }
    for (final pt in filters.selectedPropertyTypes) {
      chips.add(_appliedChip(pt, () => notifier.togglePropertyType(pt)));
    }
    if (filters.minBudget > 0.0 || filters.maxBudget < 20.0) {
      final label =
          '₹${filters.minBudget.toStringAsFixed(1)}Cr - ₹${filters.maxBudget.toStringAsFixed(1)}Cr';
      chips.add(_appliedChip(label, () => notifier.updateBudget(0.0, 20.0)));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _appliedChip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, size: 14, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Properties Found',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          GestureDetector(
            onTap: _showSortDialog,
            child: Row(
              children: [
                Text(
                  'Sort: ${_sortLabels[_sortOrder]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF667085),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    List<Property> items,
    int totalCount,
    bool hasMore,
  ) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'No results matched',
        message:
            'Try clearing some active filters or modifying search keywords.',
        asset: 'assets/illustrations/empty_search.svg',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        // Last item → Load More button
        if (i == items.length) {
          return _buildLoadMoreButton(totalCount);
        }
        final p = items[i];
        return PropertyCard(
          property: p,
          onTap: () => context.push('/property/${p.id}'),
        );
      },
    );
  }

  Widget _buildLoadMoreButton(int totalCount) {
    final remaining = totalCount - _visibleCount;
    final nextBatch = remaining.clamp(0, _pageSize);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _visibleCount += _pageSize);
          },
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          label: Text(
            'Load $nextBatch more  ($remaining remaining)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: BorderSide(color: _kPrimary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
    );
  }
}
