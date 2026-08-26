import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/filters/common_filter_provider.dart';
import '../../../data/models/property.dart';
import '../../../data/services/property_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../search/search_args.dart';
import 'property_list_args.dart';
import 'property_name_search_args.dart';

// ─── Design Tokens ───
const _kPrimary = Color(0xFFFF8000);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

// ─── Filter Model ───
class _FilterChip {
  final String label;
  final String mode; // 'buy' or 'rent'
  final String? subType; // null means "Any"

  const _FilterChip({required this.label, required this.mode, this.subType});
}

const _kFilters = <_FilterChip>[
  _FilterChip(label: 'Buy', mode: 'buy', subType: null),
  _FilterChip(label: 'Rent', mode: 'rent', subType: null),
  _FilterChip(label: 'PG / Living', mode: 'rent', subType: 'PG'),
  _FilterChip(label: 'Commercial', mode: 'buy', subType: 'Commercial'),
  _FilterChip(label: 'Land / Plot', mode: 'buy', subType: 'Plot'),
];

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({super.key});

  @override
  ConsumerState<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  // ─── base data loaded from navigation args (null = loading) ───
  List<Property>? _baseItems;
  String _title = 'Properties';
  String _currentSort = 'Relevance';

  // ─── Pagination ───
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // ─── manual area/locality search ───
  final TextEditingController _areaController = TextEditingController();

  // ─── active filter index mapped from Riverpod central state ───
  int? get _activeFilterIndex {
    final filters = ref.watch(commonFilterNotifierProvider);
    if (filters.listingType == 'buy' && filters.propertyType == 'Any') return 0;
    if (filters.listingType == 'rent' && filters.propertyType == 'Any') {
      return 1;
    }
    if (filters.listingType == 'rent' && filters.propertyType == 'PG') return 2;
    if (filters.listingType == 'buy' &&
        (filters.propertyType == 'Commercial' ||
            filters.propertyType == 'Office')) {
      return 3;
    }
    if (filters.listingType == 'buy' &&
        (filters.propertyType == 'Plot' || filters.propertyType == 'Land')) {
      return 4;
    }
    return null;
  }

  void _onFilterChipTapped(int? index) {
    final notifier = ref.read(commonFilterNotifierProvider.notifier);
    if (index == null) {
      notifier.updateListingType('Any');
      notifier.updatePropertyType('Any');
      context.pushReplacement('/properties');
    } else {
      final chip = _kFilters[index];
      notifier.updateListingType(chip.mode);
      notifier.updatePropertyType(chip.subType ?? 'Any');
      context.pushReplacement(
        '/properties',
        extra: SearchArgs(
          mode: chip.mode,
          budget: const RangeValues(0, 3000000),
          propertyType: chip.subType ?? 'Any',
          amenities: const [],
          locationQuery: '',
          fromTab: true,
        ),
      );
    }
  }

  // ─── items after applying the active chip filter and manual area search ───
  List<Property> get _filteredItems {
    final base = _baseItems;
    if (base == null) return [];
    var items = base;
    final filters = ref.read(commonFilterNotifierProvider);

    final extra = GoRouterState.of(context).extra;
    final isGenericList = extra == null;

    if (isGenericList) {
      if (filters.listingType != 'Any') {
        final lt = filters.listingType.toLowerCase();
        items = items.where((p) {
          final pt = p.type.toLowerCase();
          if (lt == 'buy' && pt == 'sale') return true;
          return pt == lt;
        }).toList();
      }

      if (filters.propertyType != 'Any') {
        final query = filters.propertyType.toLowerCase();
        items = items.where((p) {
          final pKind = p.propertyKind.toLowerCase();
          final pName = p.name.toLowerCase();
          final pType = p.type.toLowerCase();

          if (query == 'plot' || query == 'land') {
            if (pKind.contains('plot') || pKind.contains('land')) return true;
            if (pName.contains('plot') || pName.contains('land')) return true;
          }

          return pKind.contains(query) ||
              pName.contains(query) ||
              pType.contains(query);
        }).toList();
      }

      if (filters.searchText.trim().isNotEmpty) {
        final q = filters.searchText.trim().toLowerCase();
        items = items.where((p) {
          return p.location.toLowerCase().contains(q) ||
              p.name.toLowerCase().contains(q);
        }).toList();
      }
    }

    var filtered = items.toList();
    if (_currentSort == 'Price: Low to High') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_currentSort == 'Price: High to Low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadNextPage() async {
    final extra = GoRouterState.of(context).extra;
    // Currently only supporting infinite scroll on the default 'All' properties list
    if (extra != null) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await ref
          .read(propertyRepositoryProvider)
          .fetchAllPaged(page: _currentPage + 1);
      _currentPage = result.currentPage;
      _hasMore = result.hasMore;
      if (mounted) {
        setState(() {
          _baseItems = [...?_baseItems, ...result.items];
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBaseItems();
  }

  Future<void> _loadBaseItems() async {
    final extra = GoRouterState.of(context).extra;
    if (extra is SearchArgs) {
      _title = _titleForSearchArgs(extra);

      List<Property> items;
      if (extra.fromTab) {
        final loc = ref.read(locationProvider);
        if (extra.propertyType == 'Commercial') {
          final token = ref.read(authProvider).user?.token ?? '';
          final notif = ref.read(propertyNotifierProvider.notifier);
          try {
            items = (await notif.fetchCommercialPropertiesPaged(token)).items;
          } catch (e) {
            debugPrint('Error loading commercial properties: $e');
            items = [];
          }
        } else if (extra.propertyType == 'Plot') {
          final token = ref.read(authProvider).user?.token ?? '';
          final notif = ref.read(propertyNotifierProvider.notifier);
          try {
            items = (await notif.fetchLandPlotPropertiesPaged(token)).items;
          } catch (e) {
            debugPrint('Error loading plot properties: $e');
            items = [];
          }
        } else if (extra.propertyType == 'PG') {
          final token = ref.read(authProvider).user?.token ?? '';
          final notif = ref.read(propertyNotifierProvider.notifier);
          try {
            final pgItems = (await notif.fetchPgPropertiesPaged(token)).items;
            final coItems = (await notif.fetchCoLivingPropertiesPaged(
              token,
            )).items;
            items = [...pgItems, ...coItems];
          } catch (e) {
            debugPrint('Error loading PG properties: $e');
            items = [];
          }
        } else if (extra.propertyType == 'Any' && extra.mode == 'buy') {
          final token = ref.read(authProvider).user?.token ?? '';
          final notif = ref.read(propertyNotifierProvider.notifier);
          try {
            items = (await notif.fetchBuyPropertiesPaged(token)).items;
          } catch (e) {
            debugPrint('Error loading buy properties: $e');
            items = [];
          }
        } else if (extra.propertyType == 'Any' && extra.mode == 'rent') {
          final token = ref.read(authProvider).user?.token ?? '';
          final notif = ref.read(propertyNotifierProvider.notifier);
          try {
            items = (await notif.fetchRentPropertiesPaged(token)).items;
          } catch (e) {
            debugPrint('Error loading rent properties: $e');
            items = [];
          }
        } else {
          items = await ref
              .read(propertyNotifierProvider.notifier)
              .fetchForType(
                mode: extra.mode,
                propertyType: extra.propertyType == 'Any'
                    ? null
                    : extra.propertyType,
                city:
                    loc.currentLabel.isNotEmpty &&
                        loc.currentLabel != 'Unknown Location'
                    ? loc.currentLabel
                    : null,
              );
        }
      } else {
        final lq = extra.locationQuery.toLowerCase().trim();
        final token = ref.read(authProvider).user?.token ?? '';
        final notif = ref.read(propertyNotifierProvider.notifier);

        try {
          if (lq.contains('2 bhk')) {
            _title = '2 BHK Flats';
            items = await notif.fetchTwoBhkProperties(token);
          } else if (lq.contains('50l') ||
              lq.contains('50 lakh') ||
              lq.contains('under 50')) {
            _title = 'Flats Under 50 Lakhs';
            items = await notif.fetchFlatsUnderFiftyLakh(token);
          } else if (lq.contains('ready to move')) {
            _title = 'Ready to Move';
            items = await notif.fetchReadyToMoveProperties(token);
          } else if (lq.contains('furnished')) {
            _title = 'Furnished';
            items = await notif.fetchFurnishedProperties(token);
          } else if (lq.contains('gated society')) {
            _title = 'Gated Society';
            items = await notif.fetchGatedSocietyProperties(token);
          } else if (lq.contains('studio')) {
            _title = 'Studio Apartment';
            items = await notif.fetchStudioApartmentProperties(token);
          } else if (extra.propertyType == 'Apartments') {
            items = (await notif.fetchApartmentPropertiesPaged(token)).items;
          } else if (extra.propertyType == 'Independent House') {
            items = (await notif.fetchIndependentHousePropertiesPaged(
              token,
            )).items;
          } else if (extra.propertyType == 'Duplex') {
            items = (await notif.fetchDuplexPropertiesPaged(token)).items;
          } else if (extra.propertyType == 'Villa') {
            items = (await notif.fetchVillaPropertiesPaged(token)).items;
          } else if (extra.propertyType == 'Studio') {
            items = (await notif.fetchStudioPropertiesPaged(token)).items;
          } else if (extra.propertyType == 'Plot') {
            items = (await notif.fetchPlotPropertiesPaged(token)).items;
          } else {
            items = await notif.search(
              mode: extra.mode,
              budgetRange: extra.budget != null
                  ? BudgetRange(extra.budget!.start, extra.budget!.end)
                  : null,
              propertyType: extra.propertyType,
              amenities: extra.amenities,
              locationQuery: extra.locationQuery,
              sortBy: extra.sortBy,
            );
          }
        } catch (e) {
          debugPrint('Error loading specialized properties: $e');
          items = [];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not load properties: ${e.toString().replaceAll('Exception: ', '')}',
                ),
              ),
            );
          }
        }
      }
      if (mounted) setState(() => _baseItems = items);
    } else if (extra is PropertyNameSearchArgs) {
      _title = 'Search: ${extra.query}';
      final items = await ref
          .read(propertyNotifierProvider.notifier)
          .searchByName(mode: extra.mode, query: extra.query);
      if (mounted) setState(() => _baseItems = items);
    } else if (extra is PropertyListArgs) {
      _title = extra.title;
      setState(() => _baseItems = extra.items);
    } else {
      try {
        final result = await ref
            .read(propertyRepositoryProvider)
            .fetchAllPaged(page: 1);
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        if (mounted) setState(() => _baseItems = result.items);
      } catch (_) {
        if (mounted) {
          setState(() => _baseItems = ref.read(propertyNotifierProvider).all);
        }
      }
    }
  }

  String _titleForSearchArgs(SearchArgs args) {
    final type = args.propertyType;
    if (type != 'Any' && type.isNotEmpty) {
      return type == 'PG' ? 'PG / Living' : type;
    }
    return args.mode == 'buy' ? 'Buy Properties' : 'Rent Properties';
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(commonFilterNotifierProvider);

    // Synchronize controller with search text if updated externally
    if (_areaController.text != filters.searchText) {
      _areaController.text = filters.searchText;
    }

    // Watch for location changes to reload properties globally
    ref.listen(locationProvider, (previous, next) {
      if (previous?.currentLabel != next.currentLabel) {
        _loadBaseItems();
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          textAlign: TextAlign.center,
          _title,

          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: _kTextDark,
          ),
        ),
        // actions: [
        //   if (GoRouterState.of(context).extra == null)
        //     IconButton(
        //       onPressed: () => context.push('/search'),
        //       icon: const Icon(Icons.tune_rounded),
        //       tooltip: 'Filters',
        //     ),
        // ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Location + Filter Bar ───
          if (GoRouterState.of(context).extra == null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // // Location + Manual Area Search
                  // Row(
                  //   children: [
                  //     GestureDetector(
                  //       onTap: _openLocationSheet,
                  //       child: Container(
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 12,
                  //           vertical: 8,
                  //         ),
                  //         decoration: BoxDecoration(
                  //           color: _kPrimary.withValues(alpha: 0.06),
                  //           borderRadius: BorderRadius.circular(999),
                  //           border: Border.all(
                  //             color: _kPrimary.withValues(alpha: 0.22),
                  //           ),
                  //         ),
                  //         child: Row(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             const Icon(
                  //               Icons.location_on_rounded,
                  //               color: _kPrimary,
                  //               size: 15,
                  //             ),
                  //             const SizedBox(width: 6),
                  //             ConstrainedBox(
                  //               constraints: BoxConstraints(
                  //                 maxWidth:
                  //                     MediaQuery.sizeOf(context).width * 0.32,
                  //               ),
                  //               child: Text(
                  //                 location.currentLabel,
                  //                 maxLines: 1,
                  //                 overflow: TextOverflow.ellipsis,
                  //                 style: const TextStyle(
                  //                   fontSize: 13,
                  //                   fontWeight: FontWeight.w700,
                  //                   color: _kPrimary,
                  //                 ),
                  //               ),
                  //             ),
                  //             const SizedBox(width: 4),
                  //             const Icon(
                  //               Icons.keyboard_arrow_down_rounded,
                  //               color: _kPrimary,
                  //               size: 16,
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Expanded(
                  //       child: Container(
                  //         height: 36,
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFFF2F4F7),
                  //           borderRadius: BorderRadius.circular(999),
                  //           border: Border.all(color: _kBorder),
                  //         ),
                  //         padding: const EdgeInsets.symmetric(horizontal: 12),
                  //         child: Row(
                  //           children: [
                  //             const Icon(
                  //               Icons.search_rounded,
                  //               size: 16,
                  //               color: _kTextMid,
                  //             ),
                  //             const SizedBox(width: 6),
                  //             Expanded(
                  //               child: TextField(
                  //                 controller: _areaController,
                  //                 onChanged: (val) {
                  //                   ref
                  //                       .read(
                  //                         commonFilterNotifierProvider.notifier,
                  //                       )
                  //                       .updateSearchText(val);
                  //                 },
                  //                 style: const TextStyle(
                  //                   fontSize: 12.5,
                  //                   fontWeight: FontWeight.w600,
                  //                   color: _kTextDark,
                  //                 ),
                  //                 // decoration: const InputDecoration(
                  //                 //   hintText: 'Search sector/area...',
                  //                 //   hintStyle: TextStyle(
                  //                 //     fontSize: 12.5,
                  //                 //     color: _kTextMid,
                  //                 //     fontWeight: FontWeight.w500,
                  //                 //   ),
                  //                 //   border: InputBorder.none,
                  //                 //   isDense: true,
                  //                 //   contentPadding: EdgeInsets.zero,
                  //                 // ),
                  //               ),
                  //             ),
                  //             if (filters.searchText.isNotEmpty)
                  //               GestureDetector(
                  //                 onTap: () {
                  //                   ref
                  //                       .read(
                  //                         commonFilterNotifierProvider.notifier,
                  //                       )
                  //                       .updateSearchText('');
                  //                 },
                  //                 child: const Icon(
                  //                   Icons.close_rounded,
                  //                   size: 16,
                  //                   color: _kTextMid,
                  //                 ),
                  //               ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 12),

                  // Type filter chips (horizontally scrollable)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kFilters.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          final isSelected = _activeFilterIndex == null;
                          return GestureDetector(
                            onTap: () => _onFilterChipTapped(null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? _kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected ? _kPrimary : _kBorder,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _kPrimary.withValues(
                                            alpha: 0.28,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                'All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : _kTextMid,
                                ),
                              ),
                            ),
                          );
                        }
                        final chip = _kFilters[i - 1];
                        final isSelected = _activeFilterIndex == i - 1;
                        return GestureDetector(
                          onTap: () {
                            // Tap selected chip → deselect (toggle off) to show all
                            _onFilterChipTapped(isSelected ? null : i - 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? _kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? _kPrimary : _kBorder,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _kPrimary.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              chip.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : _kTextMid,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ─── Results List ───
          Expanded(
            child: _baseItems == null
                ? const _LoadingOrEmpty()
                : _buildResultList(_filteredItems),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(List<Property> items) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadBaseItems(),
        color: _kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.6,
            alignment: Alignment.center,
            child: const EmptyState(
              title: 'No Property Found',
              message:
                  'Try adjusting filters or selecting a different location.',
              asset: 'assets/illustrations/empty_search.svg',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadBaseItems(),
      color: _kPrimary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length + 1 + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? 0 : 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text(
                  //   '${items.length} Properties Found',
                  //   style: const TextStyle(
                  //     fontSize: 12.5,
                  //     fontWeight: FontWeight.w800,
                  //     color: Color(0xFF1D2939),
                  //   ),
                  // ),
                  PopupMenuButton<String>(
                    initialValue: _currentSort,
                    onSelected: (val) => setState(() => _currentSort = val),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Relevance',
                        child: Text('Relevance'),
                      ),
                      const PopupMenuItem(
                        value: 'Price: Low to High',
                        child: Text('Price: Low to High'),
                      ),
                      const PopupMenuItem(
                        value: 'Price: High to Low',
                        child: Text('Price: High to Low'),
                      ),
                    ],
                    child: Row(
                      children: [
                        Text(
                          'Sort: $_currentSort',
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
          if (i == items.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final p = items[i - 1];
          return PropertyCard(
            property: p,
            onTap: () => context.push('/property/${p.id}'),
          );
        },
      ),
    );
  }
}

// ─── Shown while base items are loading (future hasn't resolved yet) ───
class _LoadingOrEmpty extends StatelessWidget {
  const _LoadingOrEmpty();

  @override
  Widget build(BuildContext context) => const ShimmerList();
}

// ─────────────────────────────────────────────────────────────
//  LOCATION SHEET  – inline copy so it can be used from this screen
// ─────────────────────────────────────────────────────────────
class _LocationSheet extends ConsumerStatefulWidget {
  final ValueChanged<String>? onLocationChanged;
  const _LocationSheet({this.onLocationChanged});

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Enter city / locality',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(locationProvider.notifier)
                              .fetchCurrent(),
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.error!.replaceFirst('Exception: ', ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Saved locations as selectable chips
              if (state.saved.isNotEmpty) ...[
                const Text(
                  'Recent Locations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextMid,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final loc in state.saved.take(8))
                      InputChip(
                        avatar: const Icon(
                          Icons.history_rounded,
                          size: 15,
                          color: _kPrimary,
                        ),
                        label: Text(loc.label),
                        onPressed: () async {
                          await ref
                              .read(locationProvider.notifier)
                              .selectSaved(loc);
                          widget.onLocationChanged?.call(loc.label);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        onDeleted: () => ref
                            .read(locationProvider.notifier)
                            .removeSaved(loc.label),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    final v = _controller.text.trim();
                    if (v.isEmpty) return;
                    await ref.read(locationProvider.notifier).setManual(v);
                    widget.onLocationChanged?.call(v);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use this location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
