import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../data/models/property.dart';
import '../../../data/services/property_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../search/search_args.dart';
import 'property_list_args.dart';
import 'property_name_search_args.dart';

// ─── Design Tokens ───
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

// ─── Filter Model ───
class _FilterChip {
  final String label;
  final String mode;       // 'buy' or 'rent'
  final String? subType;  // null means "Any"

  const _FilterChip({
    required this.label,
    required this.mode,
    this.subType,
  });
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

  // ─── manual area/locality search ───
  final TextEditingController _areaController = TextEditingController();
  String _areaQuery = '';

  // ─── active filter index (null = no filter active, "All") ───
  int? _activeFilterIndex;

  // ─── items after applying the active chip filter and manual area search ───
  List<Property> get _filteredItems {
    final base = _baseItems;
    if (base == null) return [];
    var items = base;
    if (_activeFilterIndex != null) {
      final f = _kFilters[_activeFilterIndex!];
      items = items.where((p) {
        final modeOk = p.type == f.mode;
        final subOk = f.subType == null
            ? true
            : p.propertyKind.toLowerCase().contains(f.subType!.toLowerCase()) ||
              p.name.toLowerCase().contains(f.subType!.toLowerCase()) ||
              p.type.toLowerCase().contains(f.subType!.toLowerCase());
        return modeOk && subOk;
      }).toList();
    }

    if (_areaQuery.trim().isNotEmpty) {
      final q = _areaQuery.trim().toLowerCase();
      items = items.where((p) {
        return p.location.toLowerCase().contains(q) ||
               p.name.toLowerCase().contains(q);
      }).toList();
    }

    return items;
  }

  @override
  void dispose() {
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
        items = await ref.read(propertyProvider.notifier).fetchForType(
              mode: extra.mode,
              propertyType:
                  extra.propertyType == 'Any' ? null : extra.propertyType,
              lat: loc.lat,
              lng: loc.lng,
            );
      } else {
        final lq = extra.locationQuery.toLowerCase().trim();
        final token = ref.read(authProvider).user?.token ?? '';
        final notif = ref.read(propertyProvider.notifier);
        
        try {
          if (lq.contains('2 bhk')) {
            _title = '2 BHK Flats';
            items = await notif.fetchTwoBhkProperties(token);
          } else if (lq.contains('50l') || lq.contains('50 lakh') || lq.contains('under 50')) {
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
          } else {
            items = await notif.search(
                  mode: extra.mode,
                  budgetRange: BudgetRange(extra.budget.start, extra.budget.end),
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
              SnackBar(content: Text('Could not load properties: ${e.toString().replaceAll('Exception: ', '')}')),
            );
          }
        }
      }
      if (mounted) setState(() => _baseItems = items);
    } else if (extra is PropertyNameSearchArgs) {
      _title = 'Search: ${extra.query}';
      final items = await ref
          .read(propertyProvider.notifier)
          .searchByName(mode: extra.mode, query: extra.query);
      if (mounted) setState(() => _baseItems = items);
    } else if (extra is PropertyListArgs) {
      _title = extra.title;
      setState(() => _baseItems = extra.items);
    } else {
      setState(() => _baseItems = ref.read(propertyProvider).all);
    }
  }

  String _titleForSearchArgs(SearchArgs args) {
    final type = args.propertyType;
    if (type != 'Any' && type.isNotEmpty) {
      return type == 'PG' ? 'PG / Living' : type;
    }
    return args.mode == 'buy' ? 'Buy Properties' : 'Rent Properties';
  }

  // ─── Location sheet ───
  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationSheet(
        onLocationChanged: (_) {
          // Refresh results with new location
          setState(() => _loadBaseItems());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: _kTextDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filters',
          ),
        ],
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
                // Location + Manual Area Search
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openLocationSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _kPrimary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: _kPrimary,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.32,
                              ),
                              child: Text(
                                location.currentLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _kPrimary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _kBorder),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 16, color: _kTextMid),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _areaController,
                                onChanged: (val) {
                                  setState(() {
                                    _areaQuery = val;
                                  });
                                },
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search sector/area...',
                                  hintStyle: TextStyle(
                                    fontSize: 12.5,
                                    color: _kTextMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_areaQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _areaController.clear();
                                  setState(() {
                                    _areaQuery = '';
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: _kTextMid,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

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
                          onTap: () {
                            setState(() {
                              _activeFilterIndex = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? _kPrimary
                                    : _kBorder,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _kPrimary.withValues(alpha: 0.28),
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
                          setState(() {
                            // Tap selected chip → deselect (toggle off) to show all
                            _activeFilterIndex =
                                isSelected ? null : i - 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kPrimary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? _kPrimary
                                  : _kBorder,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _kPrimary.withValues(alpha: 0.28),
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
      return const EmptyState(
        title: 'No results',
        message: 'Try adjusting filters or selecting a different location.',
        asset: 'assets/illustrations/empty_search.svg',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length + 1,
      separatorBuilder: (context, index) =>
          SizedBox(height: index == 0 ? 0 : 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} Properties Found',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Sort: Relevance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF667085),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF667085),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        final p = items[i - 1];
        return PropertyCard(
          property: p,
          onTap: () => context.push('/property/${p.id}'),
        );
      },
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                      ActionChip(
                        avatar: const Icon(
                          Icons.history_rounded,
                          size: 15,
                          color: _kPrimary,
                        ),
                        label: Text(loc),
                        onPressed: () async {
                          await ref
                              .read(locationProvider.notifier)
                              .setManual(loc);
                          widget.onLocationChanged?.call(loc);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
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
                    await ref
                        .read(locationProvider.notifier)
                        .setManual(v);
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
