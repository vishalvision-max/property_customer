import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../search/name_search_args.dart';
import '../search/search_args.dart';

const _kPrimary = Color(0xFF5C46E8);
const _kBg = Color(0xFFF9FAFB);
const _kTextDark = Color(0xFF1D2939);
const _kTextMid = Color(0xFF667085);
const _kBorder = Color(0xFFE4E7EC);

class PropertiesTabScreen extends ConsumerStatefulWidget {
  const PropertiesTabScreen({super.key});

  @override
  ConsumerState<PropertiesTabScreen> createState() =>
      _PropertiesTabScreenState();
}

class _PropertiesTabScreenState extends ConsumerState<PropertiesTabScreen> {
  // ── Pagination state ─────────────────────────────────────────────────────
  final List<Property> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loaded = false;
  String? _error;

  // ── Filter state ──────────────────────────────────────────────────────────
  bool _panchkulaSelected = false;
  String? _selectedMode;
  String? _specialApiSelected;
  RangeValues? _selectedPriceRange;
  Set<int> _selectedBHKs = {};

  // ── Scroll controller for infinite scroll ─────────────────────────────────
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadPage(1, replace: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    await _loadPage(1, replace: true);
  }

  // ── Load a page ───────────────────────────────────────────────────────────
  Future<void> _loadPage(int page, {bool replace = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (mounted) {
      setState(() {
        if (replace) {
          _isLoading = true;
          _error = null;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final token = ref.read(authProvider).user?.token ?? '';
      List<Property> fetched = [];
      bool hasMore = false;
      int currentPage = page;

      if (_specialApiSelected != null) {
        final notif = ref.read(propertyProvider.notifier);
        final result = switch (_specialApiSelected) {
          '2 BHK' => await notif.fetchTwoBhkPropertiesPaged(token, page: page),
          'Under 50 Lakhs' => await notif.fetchFlatsUnderFiftyLakhPaged(token, page: page),
          'Ready to Move' => await notif.fetchReadyToMovePropertiesPaged(token, page: page),
          'Furnished' => await notif.fetchFurnishedPropertiesPaged(token, page: page),
          'Gated Society' => await notif.fetchGatedSocietyPropertiesPaged(token, page: page),
          'Studio Apartment' => await notif.fetchStudioApartmentPropertiesPaged(token, page: page),
          _ => throw UnimplementedError(),
        };
        fetched = result.items;
        hasMore = result.hasMore;
        currentPage = result.currentPage;
      } else if (_selectedMode == null) {
        // Default: paginated all-properties API
        final result = await ref
            .read(propertyProvider.notifier)
            .fetchAllOwnerPropertiesPaged(token, page: page);
        fetched = result.items;
        hasMore = result.hasMore;
        currentPage = result.currentPage;
      } else {
        final notif = ref.read(propertyProvider.notifier);
        switch (_selectedMode) {
          case 'Buy':
            final result = await notif.fetchBuyPropertiesPaged(token, page: page);
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Rent':
            final result = await notif.fetchRentPropertiesPaged(token, page: page);
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'PG/Living':
            final pgResult = await notif.fetchPgPropertiesPaged(token, page: page);
            final coResult = await notif.fetchCoLivingPropertiesPaged(token, page: page);
            fetched = [...pgResult.items, ...coResult.items];
            hasMore = pgResult.hasMore || coResult.hasMore;
            currentPage = page;
            break;
          case 'Commercial':
            final result = await notif.fetchCommercialPropertiesPaged(token, page: page);
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Land/Plot':
            final result = await notif.fetchLandPlotPropertiesPaged(token, page: page);
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          default:
            final loc = ref.read(locationProvider);
            final backendMode = _selectedMode == 'New Projects' ? 'buy' : 'rent';
            fetched = await notif.fetchForType(
              mode: backendMode,
              lat: loc.lat,
              lng: loc.lng,
            );
            hasMore = false;
        }
      }

      // Client-side filters
      var filtered = fetched;
      if (_panchkulaSelected) {
        filtered = filtered
            .where((p) => p.location.toLowerCase().contains('panchkula'))
            .toList();
      }
      if (_selectedMode != null) {
        final m = _selectedMode!.toLowerCase();
        if (m == 'pg/living') {
          filtered = filtered.where((p) {
            final text = '${p.name} ${p.description}'.toLowerCase();
            return text.contains('pg') ||
                text.contains('living') ||
                text.contains('co-living') ||
                text.contains('hostel');
          }).toList();
        } else if (m == 'commercial') {
          filtered = filtered.where((p) {
            final text = '${p.name} ${p.description}'.toLowerCase();
            return text.contains('commercial') ||
                text.contains('office') ||
                text.contains('shop') ||
                text.contains('retail') ||
                text.contains('showroom') ||
                text.contains('warehouse');
          }).toList();
        } else if (m == 'land/plot') {
          filtered = filtered.where((p) {
            final text = '${p.name} ${p.description}'.toLowerCase();
            return text.contains('plot') ||
                text.contains('land') ||
                text.contains('site');
          }).toList();
        }
      }
      if (_selectedBHKs.isNotEmpty) {
        filtered = filtered.where((p) {
          final specs = getPropertySpecs(p);
          final bedroomsStr =
              specs.bedrooms.replaceAll(RegExp(r'\s*Bed'), '').trim();
          final bedrooms = int.tryParse(bedroomsStr) ?? 0;
          for (final bhk in _selectedBHKs) {
            if (bhk == 4 && bedrooms >= 4) return true;
            if (bhk == bedrooms) return true;
          }
          return false;
        }).toList();
      }
      if (_selectedPriceRange != null) {
        filtered = filtered
            .where((p) =>
                p.price >= _selectedPriceRange!.start &&
                p.price <= _selectedPriceRange!.end)
            .toList();
      }

      if (mounted) {
        setState(() {
          if (replace) {
            _items
              ..clear()
              ..addAll(filtered);
          } else {
            _items.addAll(filtered);
          }
          _currentPage = currentPage;
          _hasMore = hasMore;
          _isLoading = false;
          _isLoadingMore = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading properties: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _loadMore() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    _loadPage(_currentPage + 1, replace: false);
  }

  // ── Reset filters and reload ───────────────────────────────────────────────
  void _resetAndLoad() {
    setState(() {
      _specialApiSelected = null;
      _selectedMode = null;
      _selectedPriceRange = null;
      _selectedBHKs = {};
    });
    _loadPage(1, replace: true);
  }

  void _load() => _loadPage(1, replace: true);

  void _showModePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const modes = [
          'Buy',
          'Rent',
          'PG/Living',
          'Commercial',
          'Land/Plot',
          'New Projects',
          'Builders',
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Mode / Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2939),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: modes.map((mode) {
                  final isSel = _selectedMode == mode;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedMode == mode) {
                          _selectedMode = null; // Toggle off to unselect!
                        } else {
                          _selectedMode = mode;
                        }
                        _load();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFF2EFFF) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFF5C46E8)
                              : const Color(0xFFD0D5DD),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel
                              ? const Color(0xFF5C46E8)
                              : const Color(0xFF344054),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPriceRangePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        RangeValues current =
            _selectedPriceRange ?? const RangeValues(0, 10000000);
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatVal(double val) {
              if (val >= 10000000) {
                return '₹${(val / 10000000).toStringAsFixed(1)} Cr';
              } else if (val >= 100000) {
                return '₹${(val / 100000).toStringAsFixed(0)} Lakh';
              }
              return '₹${val.toInt()}';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${formatVal(current.start)} - ${formatVal(current.end)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5C46E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: current,
                    min: 0,
                    max: 10000000,
                    divisions: 50,
                    activeColor: const Color(0xFF5C46E8),
                    inactiveColor: const Color(0xFFF2F4F7),
                    labels: RangeLabels(
                      formatVal(current.start),
                      formatVal(current.end),
                    ),
                    onChanged: (vals) {
                      setModalState(() {
                        current = vals;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPriceRange = null;
                              _load();
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPriceRange = current;
                              _load();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C46E8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBHKPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bhks = {1, 2, 3, 4};
        Set<int> tempSelected = Set.from(_selectedBHKs);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select BHK Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: bhks.map((bhk) {
                      final isSel = tempSelected.contains(bhk);
                      final label = bhk == 4 ? '4+ BHK' : '$bhk BHK';
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSel) {
                              tempSelected.remove(bhk);
                            } else {
                              tempSelected.add(bhk);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFF2EFFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF5C46E8)
                                  : const Color(0xFFD0D5DD),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? const Color(0xFF5C46E8)
                                  : const Color(0xFF344054),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBHKs.clear();
                              _load();
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBHKs = tempSelected;
                              _load();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C46E8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getBHKLabel() {
    if (_selectedBHKs.isEmpty) return 'BHK';
    final sorted = _selectedBHKs.toList()..sort();
    return '${sorted.map((bhk) => bhk == 4 ? "4+" : "$bhk").join(", ")} BHK';
  }

  String _getPriceLabel() {
    if (_selectedPriceRange == null) return 'Price';
    String format(double val) {
      if (val >= 10000000) {
        return '${(val / 10000000).toStringAsFixed(1)} Cr';
      } else if (val >= 100000) {
        return '${(val / 100000).toStringAsFixed(0)}L';
      }
      return val.toInt().toString();
    }

    return '${format(_selectedPriceRange!.start)}-${format(_selectedPriceRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kTextDark,
                size: 20,
              ),
              onPressed: () {
                // Back to home
              },
            ),
            title: const Text(
              'Properties',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                fontSize: 18,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: _kPrimary,
                  size: 22,
                ),
                tooltip: 'Filters',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(150),
              child: Column(
                children: [
                  // Filter Chips Row
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        // _FilterChip(
                        //   label: 'Panchkula',
                        //   onTap: () {
                        //     setState(() {
                        //       _panchkulaSelected = !_panchkulaSelected;
                        //       _load();
                        //     });
                        //   },
                        //   icon: _panchkulaSelected ? Icons.close_rounded : null,
                        //   isSelected: _panchkulaSelected,
                        // ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedMode ?? 'Select Mode',
                          onTap: _showModePicker,
                          isSelected: _selectedMode != null,
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Property Type',
                          onTap: () => context.push(
                            '/properties',
                            extra: SearchArgs(
                              mode: 'rent',
                              budget: const RangeValues(500, 5000),
                              propertyType: 'PG',
                              amenities: const [],
                              locationQuery: '',
                              fromTab: true,
                            ),
                          ),
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _getBHKLabel(),
                          onTap: _showBHKPicker,
                          isSelected: _selectedBHKs.isNotEmpty,
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _getPriceLabel(),
                          onTap: _showPriceRangePicker,
                          isSelected: _selectedPriceRange != null,
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'More Filters',
                          onTap: () => context.push('/search'),
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Special API Chips Row
                  SizedBox(
                    height: 38,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        '2 BHK',
                        'Under 50 Lakhs',
                        'Ready to Move',
                        'Furnished',
                        'Gated Society',
                        'Studio Apartment',
                      ].map((label) {
                        final isSel = _specialApiSelected == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSel) {
                                  _specialApiSelected = null;
                                } else {
                                  _specialApiSelected = label;
                                  // Clear other regular filters when special API is picked
                                  _selectedMode = null;
                                  _selectedPriceRange = null;
                                  _selectedBHKs.clear();
                                }
                                _load();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF5C46E8) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF5C46E8) : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? Colors.white : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar Input Trigger
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: GestureDetector(
                      onTap: () => context.push(
                        '/name-search',
                        extra: const NameSearchArgs(mode: 'rent'),
                      ),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: _kTextMid,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Search properties…',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sliver List of results
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: _kPrimary,
              child: _isLoading
                  ? const ShimmerList()
                  : _error != null && _items.isEmpty
                      ? LayoutBuilder(
                          builder: (ctx, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: EmptyState(
                                title: 'Could not load properties',
                                message: _error!,
                                asset: 'assets/illustrations/empty_search.svg',
                                action: TextButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ),
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? LayoutBuilder(
                              builder: (ctx, constraints) =>
                                  SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: constraints.maxHeight,
                                  child: EmptyState(
                                    title: 'No properties found',
                                    message:
                                        'Pull down to refresh or try a different filter.',
                                    asset:
                                        'assets/illustrations/empty_search.svg',
                                    action: TextButton.icon(
                                      onPressed: _resetAndLoad,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Clear Filters'),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              // +2: header row + bottom loader/footer
                              itemCount: _items.length + 2,
                              itemBuilder: (context, i) {
                                // ── Header row ─────────────────────────────
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        0, 4, 0, 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_items.length}${_hasMore ? '+' : ''} Properties Found',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _kTextDark,
                                          ),
                                        ),
                                        const Row(
                                          children: [
                                            Text(
                                              'Sort: Relevance',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _kTextMid,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: _kTextMid,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // ── Bottom loader / end footer ────────────
                                if (i == _items.length + 1) {
                                  if (_isLoadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _kPrimary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (!_hasMore && _items.isNotEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: Text(
                                          '— No more properties —',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _kTextMid,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }

                                // ── Property card ─────────────────────────
                                final p = _items[i - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PropertyCard(
                                    property: p,
                                    onTap: () =>
                                        context.push('/property/${p.id}'),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5C46E8).withValues(alpha: 0.3)
                : const Color(0xFFE4E7EC),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF5C46E8)
                    : const Color(0xFF344054),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFF5C46E8)
                    : const Color(0xFF667085),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
