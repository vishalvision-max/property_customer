import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/property.dart';
import '../../../data/services/property_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_list.dart';
import '../property/property_name_search_args.dart';
import '../../../providers/location_provider.dart';

// New Premium filter components
import '../../widgets/amenities_section.dart';
import '../../sheets/filter_bottom_sheet.dart';
import '../../providers/property_filter_provider.dart';
import '../../../data/models/property_filter_model.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _fieldFill = Color(0xFFF2F3F5);
const _border = Color(0xFFECEDF0);

const _kCategories = ['All', 'House', 'Villa', 'Apartments', 'Other'];

bool _matchesCategory(Property p, String category) {
  if (category == 'All') return true;
  final haystack = '${p.categoryName ?? ''} ${p.propertyKind} ${p.name}'
      .toLowerCase();
  switch (category) {
    case 'House':
      return haystack.contains('house');
    case 'Villa':
      return haystack.contains('villa');
    case 'Apartments':
      return haystack.contains('apartment') || haystack.contains('flat');
    case 'Other':
      return !_matchesCategory(p, 'House') &&
          !_matchesCategory(p, 'Villa') &&
          !_matchesCategory(p, 'Apartments');
  }
  return true;
}

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.args.query;
    // Defer provider mutations to after the first frame to avoid
    // "Tried to modify a provider while the widget tree was building" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Filters are persisted globally. Without this, arriving here from a new
      // entry point (e.g. the "Lease" quick action after "Residential") keeps
      // the previous screen's filters and every entry point resolves to the
      // same result set.
      ref.read(propertyFilterProvider.notifier).clearFilters();
      _loadBaseItems();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  void _loadMore() {
    final filters = ref.read(propertyFilterProvider);
    final category = ref.read(searchCategoryTabProvider);
    final filteredList = _getFilteredItems(filters, category);

    if (_visibleCount < filteredList.length) {
      setState(() {
        _visibleCount += _pageSize;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectFurnishing(String value) {
    if (!ref.read(propertyFilterProvider).selectedFurnishing.contains(value)) {
      ref.read(propertyFilterProvider.notifier).toggleFurnishing(value);
    }
  }

  void _selectAvailable(String value) {
    if (!ref.read(propertyFilterProvider).selectedAvailable.contains(value)) {
      ref.read(propertyFilterProvider.notifier).toggleAvailable(value);
    }
  }

  String _parseQueryAndGetKeyword(String query) {
    // If it contains a comma, only take the first part (the city/locality name)
    final cityPart = query.contains(',') ? query.split(',').first : query;
    final clean = cityPart.replaceAll(',', ' ').trim();
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();

    String? matchedIntent;
    final matchedBhk = <String>[];
    final matchedTypes = <String>[];
    final locationWords = <String>[];

    // Only clear intent/locality-related filters derived from the query text.
    // Do NOT clear BHK, property types, or budget — those are user-set filters
    // that must survive a re-search (e.g. after opening the filter bottom sheet).
    final notifier = ref.read(propertyFilterProvider.notifier);
    notifier.updateIntent('');
    notifier.removeLocality(ref.read(propertyFilterProvider).selectedCity);

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
      if (word == 'lease') {
        matchedIntent = 'Lease';
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
      if (word == 'commercial') {
        matchedTypes.add('Commercial');
        i++;
        continue;
      }
      if (word == 'residential') {
        matchedTypes.add('Residential');
        i++;
        continue;
      }
      if (word == 'pg') {
        matchedTypes.add('PG');
        i++;
        continue;
      }
      if (word == 'office' || word == 'shop' || word == 'shops') {
        matchedTypes.add('Office');
        i++;
        continue;
      }

      // Check for "ready to move"
      if (word == 'ready' &&
          i + 2 < words.length &&
          words[i + 1] == 'to' &&
          words[i + 2] == 'move') {
        _selectAvailable('Ready to Move');
        i += 3;
        continue;
      }

      // Check for furnishing
      if (word == 'furnished') {
        _selectFurnishing('Furnished');
        i++;
        continue;
      }
      if (word == 'unfurnished') {
        _selectFurnishing('Unfurnished');
        i++;
        continue;
      }
      if (word == 'semi-furnished') {
        _selectFurnishing('Semi-Furnished');
        i++;
        continue;
      }

      // Check for price ranges like "under 50l"
      if (word == 'under' && i + 1 < words.length) {
        final nextWord = words[i + 1];
        final match = RegExp(
          r'^(\d+)(l|lakh|lakhs|cr|crore|crores)$',
        ).firstMatch(nextWord);
        if (match != null) {
          final val = double.tryParse(match.group(1)!);
          if (val != null) {
            final isCr = match.group(2)!.startsWith('c');
            final maxCr = isCr ? val : val / 100.0;
            ref.read(propertyFilterProvider.notifier).updateBudget(0.0, maxCr);
          }
          i += 2;
          continue;
        } else if (RegExp(r'^\d+$').hasMatch(nextWord) &&
            i + 2 < words.length) {
          final unit = words[i + 2];
          if (unit.startsWith('l') || unit.startsWith('c')) {
            final val = double.tryParse(nextWord);
            if (val != null) {
              final isCr = unit.startsWith('c');
              final maxCr = isCr ? val : val / 100.0;
              ref
                  .read(propertyFilterProvider.notifier)
                  .updateBudget(0.0, maxCr);
            }
            i += 3;
            continue;
          }
        }
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

    // toggle* flips the value, so only call it when the filter isn't already
    // on — otherwise re-running the same query switches the filter back off.
    for (final bhk in matchedBhk) {
      if (!ref.read(propertyFilterProvider).selectedBhk.contains(bhk)) {
        ref.read(propertyFilterProvider.notifier).toggleBhk(bhk);
      }
    }
    for (final type in matchedTypes) {
      if (!ref
          .read(propertyFilterProvider)
          .selectedPropertyTypes
          .contains(type)) {
        ref.read(propertyFilterProvider.notifier).togglePropertyType(type);
      }
    }

    if (locationWords.isEmpty) {
      // No location keyword found — pass empty string so the API
      // returns all properties (fetchAll behaviour) instead of
      // doing a literal search on the raw composite query string.
      ref.read(propertyFilterProvider.notifier).updateCity('');
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

    try {
      final filters = ref.read(propertyFilterProvider);

      // Only pass type if user explicitly selected an intent.
      // Passing null means API returns all types (no type filter).
      final intentMode = filters.selectedIntent.isNotEmpty
          ? filters.selectedIntent.toLowerCase()
          : null;

      final availabilityFilter = filters.selectedAvailable.isNotEmpty
          ? filters.selectedAvailable.first.toLowerCase().replaceAll(' ', '_')
          : null;

      final items = await ref
          .read(propertyNotifierProvider.notifier)
          .search(
            mode: intentMode ?? '', // search() accepts empty string = show all
            budgetRange: BudgetRange(
              filters.minBudget * 10000000,
              filters.maxBudget * 10000000,
            ),
            locationQuery: searchKeyword,
            availability: availabilityFilter,
            furnishing: filters.selectedFurnishing,
            propertyType: filters.selectedPropertyTypes.isNotEmpty
                ? filters.selectedPropertyTypes.first
                : null,
          );
      if (mounted) {
        setState(() => _baseItems = items);
      }
    } catch (e, st) {
      debugPrint('[NameSearchResults] search error: $e\n$st');
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
      _applyFiltersAndReload();
    }
  }

  /// Fetches fresh results from the API using the current [propertyFilterProvider]
  /// state, mapping all UI filter values to their corresponding API query params.
  Future<void> _applyFiltersAndReload() async {
    final filters = ref.read(propertyFilterProvider);

    setState(() {
      _baseItems = null; // show shimmer while loading
      _visibleCount = _pageSize;
    });

    try {
      // ── 1. type: intent → API value ───────────────────────────────────────
      // ONLY sent when the user explicitly picks an intent chip.
      // No selection = null = no type param in the request.
      String? apiType;
      final intentStr = filters.selectedIntent.toLowerCase();
      if (intentStr == 'buy') {
        apiType = 'sale';
      } else if (intentStr == 'rent') {
        apiType = 'rent';
      } else if (intentStr == 'co-living') {
        apiType = 'co-living';
      } else if (intentStr == 'pg') {
        apiType = 'pg';
      } else if (intentStr == 'lease') {
        apiType = 'lease';
      }
      // intentStr is empty → apiType stays null → no type= param sent

      // ── 2. BHK → plain int list: bhk=1&bhk=2 ─────────────────────────────
      final bhkList = filters.selectedBhk
          .map((b) => RegExp(r'\d+').firstMatch(b)?.group(0))
          .whereType<String>()
          .map((d) => int.tryParse(d))
          .whereType<int>()
          .toList();

      // ── 3. Furnishing → plain key: furnishing=unfurnished ─────────────────
      // UI labels: 'Unfurnished', 'Semi Furnished', 'Fully Furnished'
      // API values: 'unfurnished' | 'semi-furnished' | 'furnished'
      const _furnishingApiMap = {
        'Unfurnished': 'unfurnished',
        'Semi Furnished': 'semi-furnished',
        'Fully Furnished': 'furnished',
      };
      final furnishingApi = filters.selectedFurnishing
          .map((f) => _furnishingApiMap[f])
          .whereType<String>()
          .toList();

      // ── 4. propertyKinds from selected property types ──────────────────────
      final propertyKinds = filters.selectedPropertyTypes.toList();

      // ── 5. Bathrooms → plain int ───────────────────────────────────────────
      // UI: '1+', '2+', '3+', '4+' → send the numeric value
      int? bathroomsNum;
      for (final b in filters.selectedBathrooms) {
        final m = RegExp(r'\d+').firstMatch(b);
        if (m != null) {
          bathroomsNum = int.tryParse(m.group(0)!);
          break;
        }
      }

      // ── 6. Added → API string ─────────────────────────────────────────────
      String? addedApi;
      if (filters.selectedAdded.isNotEmpty) {
        final raw = filters.selectedAdded.first.toLowerCase();
        if (raw.contains('yesterday'))
          addedApi = 'yesterday';
        else if (raw.contains('3'))
          addedApi = 'last_3_days';
        else if (raw.contains('week'))
          addedApi = 'last_week';
        else if (raw.contains('month'))
          addedApi = 'last_month';
      }

      // ── 7. Age of property → property_age_years as int ───────────────────
      // UI: 'Less than 1 year' → 1, 'Less than 3 years' → 3, etc.
      int? propertyAgeYears;
      if (filters.selectedAge.isNotEmpty) {
        final raw = filters.selectedAge.first.toLowerCase();
        if (raw.contains('1 year'))
          propertyAgeYears = 1;
        else if (raw.contains('3 year'))
          propertyAgeYears = 3;
        else if (raw.contains('5 year'))
          propertyAgeYears = 5;
        else if (raw.contains('10'))
          propertyAgeYears = 10;
        else
          propertyAgeYears = 5000; // more than 10
      }

      // ── 8. Availability ───────────────────────────────────────────────────
      String? availabilityApi;
      if (filters.selectedAvailable.isNotEmpty) {
        final raw = filters.selectedAvailable.first.toLowerCase();
        if (raw.contains('ready'))
          availabilityApi = 'ready_to_move';
        else if (raw.contains('week'))
          availabilityApi = 'within_a_week';
        else if (raw.contains('15'))
          availabilityApi = 'within_15_days';
        else if (raw.contains('month') && !raw.contains('after'))
          availabilityApi = 'within_a_month';
        else if (raw.contains('after'))
          availabilityApi = 'after_a_month';
      }

      // ── 9. Budget: convert Cr → rupees ────────────────────────────────────
      int? minPriceApi = filters.minBudget > 0.0
          ? (filters.minBudget * 10000000).toInt()
          : null;
      int? maxPriceApi = filters.maxBudget < 20.0
          ? (filters.maxBudget * 10000000).toInt()
          : null;

      // ── 10. Area ──────────────────────────────────────────────────────────
      double? minAreaApi = filters.minArea > 0.0 ? filters.minArea : null;
      double? maxAreaApi = filters.maxArea < 5000.0 ? filters.maxArea : null;

      // ── 11. City ─────────────────────────────────────────────────────────
      final cityApi = filters.selectedCity.isNotEmpty
          ? filters.selectedCity
          : null;

      // ── 12. Amenities → numeric IDs ───────────────────────────────────────
      final amenityIds = AmenitiesSection.toApiIds(filters.selectedAmenities);

      final items = await ref
          .read(propertyNotifierProvider.notifier)
          .fetchWithFilters(
            type: apiType,
            furnishing: furnishingApi,
            bhk: bhkList,
            city: cityApi,
            amenities: amenityIds,
            bathrooms: bathroomsNum,
            minArea: minAreaApi,
            maxArea: maxAreaApi,
            added: addedApi,
            propertyAgeYears: propertyAgeYears,
            availability: availabilityApi,
            minPrice: minPriceApi,
            maxPrice: maxPriceApi,
            propertyKinds: propertyKinds,
          );

      if (mounted) {
        setState(() => _baseItems = items);
      }
    } catch (e) {
      debugPrint('[NameSearchResults] _applyFiltersAndReload error: $e');
      if (mounted) setState(() => _baseItems = []);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    color: isSelected ? _orange : _navy,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: _orange)
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
        final pt = p.type.toLowerCase();
        final intentStr = filters.selectedIntent.toLowerCase();

        // Base API type check
        if ((intentStr == 'rent' ||
                intentStr == 'lease' ||
                intentStr == 'pg/co-living') &&
            pt != 'rent' &&
            pt != 'lease' &&
            pt != 'pg' &&
            pt != 'co-living' &&
            pt != 'co-livin')
          return false;
        if ((intentStr == 'buy' ||
                intentStr == 'villas' ||
                intentStr == 'bungalows' ||
                intentStr == 'land/plots' ||
                intentStr == 'commercial lands') &&
            pt != 'buy' &&
            pt != 'sale')
          return false;

        // Specific property kind checks for the new intent modes
        final kindClean = p.propertyKind.toLowerCase();
        final nameClean = p.name.toLowerCase();

        if (intentStr == 'commercial' &&
            !kindClean.contains('commercial') &&
            !nameClean.contains('office'))
          return false;
        if (intentStr == 'commercial lands' &&
            !kindClean.contains('commercial') &&
            !kindClean.contains('land') &&
            !kindClean.contains('plot'))
          return false;
        if ((intentStr == 'land/plots' || intentStr == 'lands/plots') &&
            !kindClean.contains('land') &&
            !kindClean.contains('plot'))
          return false;
        if (intentStr == 'pg/co-living' &&
            !kindClean.contains('pg') &&
            !kindClean.contains('living'))
          return false;
        if (intentStr == 'villas' &&
            !kindClean.contains('villa') &&
            !nameClean.contains('villa'))
          return false;
        if (intentStr == 'bungalows' &&
            !kindClean.contains('bungalow') &&
            !nameClean.contains('bungalow'))
          return false;
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

      // 3. BHK Match (Local Filter)
      if (filters.selectedBhk.isNotEmpty) {
        bool bhkMatch = false;
        final int propertyBhk = p.bhk ?? 0;

        for (final bhkString in filters.selectedBhk) {
          final digitsMatch = RegExp(r'(\d+)').firstMatch(bhkString);
          if (digitsMatch != null) {
            final int filterValue = int.parse(digitsMatch.group(0)!);
            if (bhkString.contains('+')) {
              if (propertyBhk >= filterValue) {
                bhkMatch = true;
                break;
              }
            } else {
              if (propertyBhk == filterValue) {
                bhkMatch = true;
                break;
              }
            }
          }
        }
        if (!bhkMatch) return false;
      }

      // 4. Property Type Match
      if (filters.selectedPropertyTypes.isNotEmpty) {
        bool typeMatch = false;
        final kindClean = p.propertyKind.toLowerCase();
        final catClean = (p.categoryName ?? '').toLowerCase();
        final nameClean = p.name.toLowerCase();

        for (final type in filters.selectedPropertyTypes) {
          // Handle plurals (e.g., "Apartments" -> "apartment")
          final t = type.toLowerCase().replaceAll(RegExp(r's$'), '');

          if (t == 'industrial shed' &&
              (kindClean.contains('industrial') ||
                  catClean.contains('industrial'))) {
            typeMatch = true;
            break;
          }
          if (t == 'agricultural land' &&
              (kindClean.contains('agricultur') ||
                  catClean.contains('agricultur'))) {
            typeMatch = true;
            break;
          }

          if (kindClean.contains(t) ||
              catClean.contains(t) ||
              nameClean.contains(t)) {
            typeMatch = true;
            break;
          }
        }
        if (!typeMatch) return false;
      }

      // 5. Category Tab Match
      if (!_matchesCategory(p, category)) return false;

      // 6. (API handles Budget Match - removed local filter)

      // 7. Advanced Filters Match (Local-only filters)
      if (filters.verifiedOnly &&
          !p.description.toLowerCase().contains('verified'))
        return false;
      if (filters.imagesOnly && p.images.isEmpty) return false;

      if (filters.selectedLeaseTypes.isNotEmpty && p.description.isNotEmpty) {
        bool leaseMatch = false;
        for (final l in filters.selectedLeaseTypes) {
          if (p.description.toLowerCase().contains(l.toLowerCase()))
            leaseMatch = true;
        }
        if (!leaseMatch) return false;
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

    // Watch for location changes to reload properties globally
    ref.listen(locationProvider, (previous, next) {
      if (previous?.currentLabel != next.currentLabel) {
        _loadBaseItems();
      }
    });
    final category = ref.watch(searchCategoryTabProvider);

    final filteredList = _getFilteredItems(filters, category);
    // Clamp visible count to total available
    final visibleList = filteredList.take(_visibleCount).toList();
    final hasMore = _visibleCount < filteredList.length;

    if (_searchController.text != filters.selectedCity &&
        filters.selectedCity.isNotEmpty) {
      _searchController.text = filters.selectedCity;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(filters, notifier),
            _buildCategoryTabs(category),
            _buildResultsHeader(filteredList.length, category),
            Expanded(
              child: _baseItems == null
                  ? const ShimmerList()
                  : _buildResultsList(
                      visibleList,
                      filteredList.length,
                      hasMore,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _navy,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Search for Your Ideal Home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _fieldFill,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _navy,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildSearchBar(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: _grey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _navy,
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
                  hintText: 'Search something',
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    color: _grey,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openFilterBottomSheet,
              child: const Icon(Icons.tune_rounded, color: _navy, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(String category) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _kCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _kCategories[i];
          final selected = cat == category;
          return GestureDetector(
            onTap: () =>
                ref.read(searchCategoryTabProvider.notifier).state = cat,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? _orange : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _orange : _border),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : _navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(int count, String category) {
    final label = category == 'All' ? 'Properties' : category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Found $count $label',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          GestureDetector(
            onTap: _showSortDialog,
            child: const Icon(Icons.swap_vert_rounded, color: _grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Property> items, int totalCount, bool hasMore) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'No Property Found',
        message:
            'Try clearing some active filters or modifying search keywords.',
        asset: 'assets/illustrations/empty_search.svg',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        // Last item → Show loading indicator for smooth pagination
        if (i == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_orange),
                ),
              ),
            ),
          );
        }
        final p = items[i];
        return _SearchResultCard(
          property: p,
          onTap: () => context.push('/property/${p.id}'),
        );
      },
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final Property property;
  final VoidCallback onTap;
  const _SearchResultCard({required this.property, required this.onTap});

  String _formatPrice(int price, String type) {
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
    }
    if (price >= 10000000) {
      double crores = price / 10000000.0;
      return '₹${crores.toStringAsFixed(crores % 1 == 0 ? 0 : 2)} Cr';
    } else if (price >= 100000) {
      double lakhs = price / 100000.0;
      return '₹${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh';
    }
    return '₹$price';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthed = ref.watch(authProvider).user != null;
    final isFav = ref.watch(
      favoritesProvider.select((s) => s.contains(property.id)),
    );
    final p = property;

    void toggleFavorite() {
      if (!isAuthed) {
        AppSnackbar.showError(context, 'Please login to add favorites');
        context.push('/login?from=${Uri.encodeComponent('/property/${p.id}')}');
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: p.images.isEmpty
                        ? 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=900&q=80&auto=format&fit=crop'
                        : p.images.first.trim(),
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 90, width: 90, color: Colors.white),
                    errorWidget: (context, url, error) =>
                        Container(height: 90, width: 90, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: _orange, size: 11),
                        SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: toggleFavorite,
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFE0245E) : _grey,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(p.price, p.type),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _orange,
                    ),
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
