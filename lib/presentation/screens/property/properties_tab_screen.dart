import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/filters/common_filter_provider.dart';
import '../../../data/models/property.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../../../providers/nav_provider.dart';
import '../home/map_location_screen.dart';

const _kPrimary = Color(0xFFFF8000);
const _kBg = Color(0xFFF9FAFB);
const _kTextDark = Color(0xFF1D2939);
const _kTextMid = Color(0xFF667085);

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

  // ── Centralized Filter Mappings (reading commonFilterNotifierProvider) ────
  String get _selectedCity {
    final city = ref.read(commonFilterNotifierProvider).city;
    if (city.isNotEmpty) return city.split(',').first.trim();

    final locLabel = ref.read(locationProvider).currentLabel;
    if (locLabel != 'Set location') {
      return locLabel.split(',').first.trim();
    }
    return '';
  }

  String get _selectedState {
    final state = ref.read(commonFilterNotifierProvider).state;
    if (state.isNotEmpty) return state;

    final locLabel = ref.read(locationProvider).currentLabel;
    if (locLabel != 'Set location' && locLabel != 'Unknown Location') {
      final parts = locLabel.split(',');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return '';
  }

  bool get _panchkulaSelected =>
      ref.read(commonFilterNotifierProvider).city.isNotEmpty;

  String? get _selectedMode {
    final mode = ref.read(commonFilterNotifierProvider).listingType;
    return mode == 'Any' ? null : mode;
  }

  String? get _specialApiSelected {
    final search = ref.read(commonFilterNotifierProvider).searchText;
    const specials = [
      '2 BHK',
      'Under 50 Lakhs',
      'Ready to Move',
      'Furnished',
      // 'Gated Society',
      'Studio Apartment',
    ];
    return specials.contains(search) ? search : null;
  }

  String? get _selectedPropertyType {
    final pt = ref.read(commonFilterNotifierProvider).propertyType;
    return pt.isEmpty || pt == 'Any' ? null : pt;
  }

  RangeValues? get _selectedPriceRange =>
      ref.read(commonFilterNotifierProvider).priceRange;

  Set<int> get _selectedBHKs {
    final beds = ref.read(commonFilterNotifierProvider).bedrooms;
    return beds != null ? {beds} : {};
  }

  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  // ── Scroll controller for infinite scroll ─────────────────────────────────
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(commonFilterNotifierProvider);
    final initialCity = filter.city.isEmpty ? 'Panchkula' : filter.city;
    final initialState = filter.state.isEmpty ? 'Haryana' : filter.state;
    _cityController = TextEditingController(text: initialCity);
    _stateController = TextEditingController(text: initialState);
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
    _cityController.dispose();
    _stateController.dispose();
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
        final notif = ref.read(propertyNotifierProvider.notifier);
        final result = switch (_specialApiSelected) {
          '2 BHK' => await notif.fetchTwoBhkPropertiesPaged(token, page: page),
          'Under 50 Lakhs' => await notif.fetchFlatsUnderFiftyLakhPaged(
            token,
            page: page,
          ),
          'Ready to Move' => await notif.fetchReadyToMovePropertiesPaged(
            token,
            page: page,
          ),
          'Furnished' => await notif.fetchFurnishedPropertiesPaged(
            token,
            page: page,
          ),
          'Gated Society' => await notif.fetchGatedSocietyPropertiesPaged(
            token,
            page: page,
          ),
          'Studio Apartment' => await notif.fetchStudioApartmentPropertiesPaged(
            token,
            page: page,
          ),
          _ => throw UnimplementedError(),
        };
        fetched = result.items;
        hasMore = result.hasMore;
        currentPage = result.currentPage;
      } else if (_selectedPropertyType != null &&
          [
            'Apartments',
            'Independent House',
            'Duplex',
            'Villa',
            'Studio',
            'Plot',
            'Industrial Shed',
            'Agricultural Land',
          ].contains(_selectedPropertyType)) {
        final notif = ref.read(propertyNotifierProvider.notifier);
        switch (_selectedPropertyType) {
          case 'Apartments':
            final result = await notif.fetchApartmentPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Independent House':
            final result = await notif.fetchIndependentHousePropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Duplex':
            final result = await notif.fetchDuplexPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Villa':
            final result = await notif.fetchVillaPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Studio':
            final result = await notif.fetchStudioPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Plot':
            final result = await notif.fetchPlotPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Industrial Shed':
            final result = await notif.fetchIndustrialShedPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Agricultural Land':
            final result = await notif.fetchAgriculturalLandPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
        }
      } else if (_selectedMode == null) {
        // Default: paginated all-properties API
        final result = await ref
            .read(propertyNotifierProvider.notifier)
            .fetchAllOwnerPropertiesPaged(
              token,
              page: page,
              city: _panchkulaSelected ? _selectedCity : null,
              bhk: _selectedBHKs.isNotEmpty ? _selectedBHKs.first : null,
            );
        fetched = result.items;
        hasMore = result.hasMore;
        currentPage = result.currentPage;
      } else {
        final notif = ref.read(propertyNotifierProvider.notifier);
        switch (_selectedMode) {
          case 'Buy':
            final result = await notif.fetchBuyPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Rent':
            final result = await notif.fetchRentPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'PG/Living':
            final pgResult = await notif.fetchPgPropertiesPaged(
              token,
              page: page,
            );
            final coResult = await notif.fetchCoLivingPropertiesPaged(
              token,
              page: page,
            );
            fetched = [...pgResult.items, ...coResult.items];
            hasMore = pgResult.hasMore || coResult.hasMore;
            currentPage = page;
            break;
          case 'Commercial':
            final result = await notif.fetchCommercialPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          case 'Land/Plot':
            final result = await notif.fetchLandPlotPropertiesPaged(
              token,
              page: page,
            );
            fetched = result.items;
            hasMore = result.hasMore;
            currentPage = result.currentPage;
            break;
          default:
            final loc = ref.read(locationProvider);
            final backendMode = 'rent';
            fetched = await notif.fetchForType(
              mode: backendMode,
              city:
                  loc.currentLabel.isNotEmpty &&
                      loc.currentLabel != 'Unknown Location'
                  ? _selectedCity
                  : null,
              state: _selectedState.isNotEmpty ? _selectedState : null,
            );
            hasMore = false;
        }
      }

      // Client-side filters
      var filtered = fetched;

      if (_selectedPropertyType != null &&
          ![
            'Apartments',
            'Independent House',
            'Duplex',
            'Villa',
            'Studio',
            'Plot',
            'Industrial Shed',
            'Agricultural Land',
          ].contains(_selectedPropertyType)) {
        filtered = filtered.where((p) {
          final pt = _selectedPropertyType!.toLowerCase();
          final kind = p.propertyKind.toLowerCase();
          final name = p.name.toLowerCase();
          final categoryName = (p.categoryName ?? '').toLowerCase();

          if (pt == 'industrial shed' &&
              (kind.contains('industrial') ||
                  categoryName.contains('industrial')))
            return true;
          if (pt == 'agricultural land' &&
              (kind.contains('agricultur') ||
                  categoryName.contains('agricultur')))
            return true;

          return kind.contains(pt) ||
              name.contains(pt) ||
              categoryName.contains(pt);
        }).toList();
      }
      if (_selectedBHKs.isNotEmpty) {
        filtered = filtered.where((p) {
          final specs = getPropertySpecs(p);
          final bedroomsStr = specs.bedrooms
              .replaceAll(RegExp(r'\s*Bed'), '')
              .trim();
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
            .where(
              (p) =>
                  p.price >= _selectedPriceRange!.start &&
                  p.price <= _selectedPriceRange!.end,
            )
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
    ref.read(commonFilterNotifierProvider.notifier).resetFilters();
    _loadPage(1, replace: true);
  }

  void _load() => _loadPage(1, replace: true);

  void _showLocationPickerDialog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MapLocationScreen()));
  }

  void _showModePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const modes = ['Buy', 'Rent', 'PG/Living', 'Commercial', 'Land/Plot'];
        return SizedBox(
          width: double.infinity,
          child: Padding(
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
                        final notifier = ref.read(
                          commonFilterNotifierProvider.notifier,
                        );
                        if (_selectedMode == mode) {
                          notifier.updateListingType('Any');
                        } else {
                          notifier.updateListingType(mode);
                        }
                        _load();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFF1E0) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFFFF8000)
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
                                ? const Color(0xFFFF8000)
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
          ),
        );
      },
    );
  }

  void _showPropertyTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const types = [
          'Apartments',
          'Independent House',
          'Builder Floor',
          'Plot',
          'Studio',
          'Duplex',
          'Agricultural Land',
          'Industrial Shed',
          'Villa',
        ];
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Property Type',
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
                  children: types.map((type) {
                    final isSel = _selectedPropertyType == type;
                    return GestureDetector(
                      onTap: () {
                        final notifier = ref.read(
                          commonFilterNotifierProvider.notifier,
                        );
                        if (_selectedPropertyType == type) {
                          notifier.updatePropertyType('Any');
                        } else {
                          notifier.updatePropertyType(type);
                        }
                        _load();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFF1E0) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFFFF8000)
                                : const Color(0xFFD0D5DD),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? const Color(0xFFFF8000)
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
                      color: Color(0xFFFF8000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: current,
                    min: 0,
                    max: 10000000,
                    divisions: 50,
                    activeColor: const Color(0xFFFF8000),
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
                            ref
                                .read(commonFilterNotifierProvider.notifier)
                                .updatePriceRange(null);
                            _load();
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
                            ref
                                .read(commonFilterNotifierProvider.notifier)
                                .updatePriceRange(current);
                            _load();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8000),
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
                                ? const Color(0xFFFFF1E0)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFFF8000)
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
                                  ? const Color(0xFFFF8000)
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
                            ref
                                .read(commonFilterNotifierProvider.notifier)
                                .updateBedrooms(null);
                            _load();
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
                            ref
                                .read(commonFilterNotifierProvider.notifier)
                                .updateBedrooms(
                                  tempSelected.isNotEmpty
                                      ? tempSelected.first
                                      : null,
                                );
                            _load();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8000),
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
    // Watch for changes so the UI reactively updates when filters change
    ref.watch(commonFilterNotifierProvider);

    // Watch for location changes to reload properties globally
    ref.listen(locationProvider, (previous, next) {
      if (previous?.currentLabel != next.currentLabel) {
        _load();
      }
    });

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
                ref.read(navProvider.notifier).goTo(0);
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

            // actions: [
            //   IconButton(
            //     onPressed: () => context.push('/search'),
            //     icon: const Icon(
            //       Icons.tune_rounded,
            //       color: _kPrimary,
            //       size: 22,
            //     ),
            //     tooltip: 'Filters',
            //   ),
            // ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(102),
              child: Column(
                children: [
                  // Filter Chips Row
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: _selectedCity,
                          onTap: () {
                            if (_panchkulaSelected) {
                              ref
                                  .read(commonFilterNotifierProvider.notifier)
                                  .updateCity('');
                              ref
                                  .read(commonFilterNotifierProvider.notifier)
                                  .updateState('');
                              _load();
                            } else {
                              _showLocationPickerDialog();
                            }
                          },
                          icon: _panchkulaSelected
                              ? Icons.close_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          isSelected: _panchkulaSelected,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedMode ?? 'Select Mode',
                          onTap: _showModePicker,
                          isSelected: _selectedMode != null,
                          icon: Icons.keyboard_arrow_down_rounded,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedPropertyType ?? 'Property Type',
                          onTap: _showPropertyTypePicker,
                          isSelected: _selectedPropertyType != null,
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
                        // const SizedBox(width: 8),
                        // _FilterChip(
                        //   label: 'More Filters',
                        //   onTap: () => context.push('/search'),
                        //   icon: Icons.keyboard_arrow_down_rounded,
                        // ),
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
                      children:
                          [
                            '2 BHK',
                            'Under 50 Lakhs',
                            'Ready to Move',
                            'Furnished',
                            // 'Gated Society',
                            'Studio Apartment',
                          ].map((label) {
                            final isSel = _specialApiSelected == label;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  final notifier = ref.read(
                                    commonFilterNotifierProvider.notifier,
                                  );
                                  if (isSel) {
                                    notifier.updateSearchText('');
                                  } else {
                                    notifier.resetFilters();
                                    notifier.updateSearchText(label);
                                  }
                                  _load();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? const Color(0xFFFF8000)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSel
                                          ? const Color(0xFFFF8000)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSel
                                          ? Colors.white
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // // Search Bar Input Trigger
                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  //   child: GestureDetector(
                  //     onTap: () => context.push(
                  //       '/name-search',
                  //       extra: const NameSearchArgs(mode: 'rent'),
                  //     ),
                  //     child: Container(
                  //       height: 40,
                  //       padding: const EdgeInsets.symmetric(horizontal: 14),
                  //       decoration: BoxDecoration(
                  //         color: _kBg,
                  //         borderRadius: BorderRadius.circular(10),
                  //         border: Border.all(color: _kBorder),
                  //       ),
                  //       child: Row(
                  //         children: [
                  //           const Icon(
                  //             Icons.search_rounded,
                  //             color: _kTextMid,
                  //             size: 18,
                  //           ),
                  //           const SizedBox(width: 10),
                  //           Text(
                  //             'Search properties…',
                  //             style: TextStyle(
                  //               color: Colors.grey.shade400,
                  //               fontSize: 13,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                      builder: (ctx, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: EmptyState(
                            title: 'No properties found',
                            message:
                                'Pull down to refresh or try a different filter.',
                            asset: 'assets/illustrations/empty_search.svg',
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      // +2: header row + bottom loader/footer
                      itemCount: _items.length + 2,
                      itemBuilder: (context, i) {
                        // ── Header row ─────────────────────────────
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_items.length}${_hasMore ? '+' : ''} Properties Found',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _kTextDark,
                                  ),
                                ),
                                // const Row(
                                //   children: [
                                //     Text(
                                //       'Sort: Relevance',
                                //       style: TextStyle(
                                //         fontSize: 12,
                                //         fontWeight: FontWeight.w700,
                                //         color: _kTextMid,
                                //       ),
                                //     ),
                                //     SizedBox(width: 4),
                                //     Icon(
                                //       Icons.keyboard_arrow_down_rounded,
                                //       color: _kTextMid,
                                //       size: 16,
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
                          );
                        }

                        // ── Bottom loader / end footer ────────────
                        if (i == _items.length + 1) {
                          if (_isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
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
                              padding: EdgeInsets.symmetric(vertical: 20),
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
                            onTap: () => context.push('/property/${p.id}'),
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
          color: isSelected ? const Color(0xFFFFF1E0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF8000).withValues(alpha: 0.3)
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
                    ? const Color(0xFFFF8000)
                    : const Color(0xFF344054),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFFFF8000)
                    : const Color(0xFF667085),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw Parks (green areas)
    paint.color = const Color(0xFFD4E6D2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 30, 100, 70),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(380, 120, 140, 80),
        const Radius.circular(8),
      ),
      paint,
    );

    // Draw River (blue wavy area)
    paint.color = const Color(0xFFB9D8F2);
    final path = Path()
      ..moveTo(0, 200)
      ..quadraticBezierTo(150, 180, 300, 220)
      ..quadraticBezierTo(450, 260, 600, 210)
      ..lineTo(600, 260)
      ..lineTo(0, 260)
      ..close();
    canvas.drawPath(path, paint);

    // Draw Major Roads (light-grey intersecting lines)
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 100), const Offset(600, 100), roadPaint);
    canvas.drawLine(const Offset(220, 0), const Offset(220, 300), roadPaint);
    canvas.drawLine(const Offset(400, 0), const Offset(400, 300), roadPaint);

    // Draw Minor Roads (thin lines)
    roadPaint.strokeWidth = 6;
    roadPaint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawLine(const Offset(0, 40), const Offset(220, 40), roadPaint);
    canvas.drawLine(const Offset(220, 160), const Offset(600, 160), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
