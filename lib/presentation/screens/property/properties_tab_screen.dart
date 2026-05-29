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
import '../search/search_args.dart';
import '../../../providers/nav_provider.dart';

const _kPrimary = Color(0xFF5C46E8);
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

  // ── Centralized Filter Mappings (watching commonFilterNotifierProvider) ────
  String get _selectedCity {
    final city = ref.watch(commonFilterNotifierProvider).city;
    return city.isEmpty ? 'Panchkula' : city;
  }

  String get _selectedState {
    final state = ref.watch(commonFilterNotifierProvider).state;
    return state.isEmpty ? 'Haryana' : state;
  }

  bool get _panchkulaSelected => ref.watch(commonFilterNotifierProvider).city.isNotEmpty;

  String? get _selectedMode {
    final mode = ref.watch(commonFilterNotifierProvider).listingType;
    return mode == 'Any' ? null : mode;
  }

  String? get _specialApiSelected {
    final search = ref.watch(commonFilterNotifierProvider).searchText;
    const specials = ['2 BHK', 'Under 50 Lakhs', 'Ready to Move', 'Furnished', 'Gated Society', 'Studio Apartment'];
    return specials.contains(search) ? search : null;
  }

  RangeValues? get _selectedPriceRange => ref.watch(commonFilterNotifierProvider).priceRange;

  Set<int> get _selectedBHKs {
    final beds = ref.watch(commonFilterNotifierProvider).bedrooms;
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
      } else if (_selectedMode == null) {
        // Default: paginated all-properties API
        final result = await ref
            .read(propertyNotifierProvider.notifier)
            .fetchAllOwnerPropertiesPaged(
              token,
              page: page,
              city: _panchkulaSelected ? _selectedCity : null,
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
            final backendMode = _selectedMode == 'New Projects'
                ? 'buy'
                : 'rent';
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
            .where(
              (p) => p.location.toLowerCase().contains(
                _selectedCity.toLowerCase(),
              ),
            )
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
    _cityController.text = _selectedCity;
    _stateController.text = _selectedState;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        bool isDetecting = false;
        double currentLat = 30.6942;
        double currentLng = 76.8606;
        double dragOffsetX = 0.0;
        double dragOffsetY = 0.0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E7EC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F4F7),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Map Preview Card
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Map street pattern mock with drag offset
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setModalState(() {
                                dragOffsetX += details.primaryDelta ?? 0;
                                currentLng -=
                                    (details.primaryDelta ?? 0) * 0.0001;
                              });
                            },
                            onVerticalDragUpdate: (details) {
                              setModalState(() {
                                dragOffsetY += details.primaryDelta ?? 0;
                                currentLat +=
                                    (details.primaryDelta ?? 0) * 0.0001;
                              });
                            },
                            child: Container(
                              color: const Color(0xFFE8ECEF),
                              child: Stack(
                                children: [
                                  // Mock Roads & Blocks
                                  Positioned(
                                    left: -100 + dragOffsetX,
                                    top: -50 + dragOffsetY,
                                    child: SizedBox(
                                      width: 600,
                                      height: 300,
                                      child: CustomPaint(
                                        painter: _MockMapPainter(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Translucent Coordinates HUD
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.explore_rounded,
                                    color: Colors.greenAccent,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentLat.toStringAsFixed(4)}° N, ${currentLng.toStringAsFixed(4)}° E',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Translucent Drag Indicator Overlay
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Drag map to pan',
                                style: TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Static Glowing Location Pin in Center
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: _kPrimary,
                                  size: 36,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Ripple dot shadow
                                Container(
                                  width: 8,
                                  height: 2.5,
                                  decoration: const BoxDecoration(
                                    color: Colors.black38,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Manual Inputs: City and State
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'City',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _cityController,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Panchkula',
                                  prefixIcon: const Icon(
                                    Icons.location_city_rounded,
                                    size: 18,
                                  ),
                                  prefixIconColor: const Color(0xFF667085),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD0D5DD),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _kPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'State',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _stateController,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Haryana',
                                  prefixIcon: const Icon(
                                    Icons.map_rounded,
                                    size: 18,
                                  ),
                                  prefixIconColor: const Color(0xFF667085),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD0D5DD),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _kPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // GPS Auto-detect Trigger
                    OutlinedButton.icon(
                      onPressed: isDetecting
                          ? null
                          : () async {
                              setModalState(() {
                                isDetecting = true;
                              });
                              try {
                                final enabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!enabled)
                                  throw Exception(
                                    'Location services are disabled',
                                  );

                                var permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                }
                                if (permission == LocationPermission.denied ||
                                    permission ==
                                        LocationPermission.deniedForever) {
                                  throw Exception('Permission denied');
                                }

                                final pos = await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.low,
                                  ),
                                );

                                // Reverse geocode
                                final placemarks =
                                    await placemarkFromCoordinates(
                                      pos.latitude,
                                      pos.longitude,
                                    );
                                if (placemarks.isNotEmpty) {
                                  final place = placemarks.first;
                                  setModalState(() {
                                    _cityController.text =
                                        place.locality ?? 'Panchkula';
                                    _stateController.text =
                                        place.administrativeArea ?? 'Haryana';
                                    currentLat = pos.latitude;
                                    currentLng = pos.longitude;
                                  });
                                }
                              } catch (e) {
                                // Denied or error - fallback to beautiful dummy detection
                                setModalState(() {
                                  _cityController.text = 'Panchkula';
                                  _stateController.text = 'Haryana';
                                  currentLat = 30.6942;
                                  currentLng = 76.8606;
                                });
                              } finally {
                                setModalState(() {
                                  isDetecting = false;
                                });
                              }
                            },
                      icon: isDetecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kPrimary,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(
                        isDetecting
                            ? 'Detecting GPS Location...'
                            : 'Use My GPS Location',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              ref.read(commonFilterNotifierProvider.notifier).updateCity('');
                              ref.read(commonFilterNotifierProvider.notifier).updateState('');
                              Navigator.pop(context);
                              _load();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Clear Filter',
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final city = _cityController.text.trim();
                              final state = _stateController.text.trim();
                              if (city.isNotEmpty) {
                                final notifier = ref.read(commonFilterNotifierProvider.notifier);
                                notifier.updateCity(city);
                                notifier.updateState(state);
                                Navigator.pop(context);
                                _load();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Apply Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showModePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const modes = ['Buy', 'Rent', 'PG/Living', 'Commercial', 'Land/Plot'];
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
                      final notifier = ref.read(commonFilterNotifierProvider.notifier);
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
                            ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(null);
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
                            ref.read(commonFilterNotifierProvider.notifier).updatePriceRange(current);
                            _load();
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
                            ref.read(commonFilterNotifierProvider.notifier).updateBedrooms(null);
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
                            ref.read(commonFilterNotifierProvider.notifier).updateBedrooms(tempSelected.isNotEmpty ? tempSelected.first : null);
                            _load();
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
                              ref.read(commonFilterNotifierProvider.notifier).updateCity('');
                              ref.read(commonFilterNotifierProvider.notifier).updateState('');
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
                      children:
                          [
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
                                  final notifier = ref.read(commonFilterNotifierProvider.notifier);
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
                                        ? const Color(0xFF5C46E8)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSel
                                          ? const Color(0xFF5C46E8)
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
