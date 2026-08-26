import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property_filter_model.dart';
import '../../../data/services/google_geocoding_service.dart';
import '../../../providers/app_providers.dart';
import '../../providers/property_filter_provider.dart';
import '../../widgets/amenities_section.dart';
import '../../widgets/area_section.dart';
import '../../widgets/bhk_section.dart';
import '../../widgets/budget_section.dart';
import '../../widgets/listed_by_section.dart';
import '../property/property_name_search_args.dart';

const _navy = Color(0xFF191D31);
const _grey = Color(0xFF666876);
const _orange = Color(0xFFFF8000);
const _orangeTint = Color(0xFFFFF1E0);
const _border = Color(0xFFE5E7EB);

const _kPopularCities = [
  'Noida',
  'Delhi',
  'Mumbai',
  'Chennai',
  'Gurgaon',
  'Bangalore',
  'Hyderabad',
  'Pune',
];

/// Display label → real filterable property_type value (see
/// PropertyTypeSection.categoryIdMap). A couple of these are best-effort
/// approximations since the app has no exact matching category for
/// "Serviced Apartment" or "Farm House".
const _kPropertyTypeMap = {
  'Flat/Apartment': ('Apartments', Icons.apartment_rounded),
  'House/Villa': ('Villa', Icons.holiday_village_rounded),
  'Serviced Apartment': ('Apartments', Icons.hotel_rounded),
  'Farm House': ('Independent House', Icons.cottage_rounded),
  'Plot/Land': ('Plot', Icons.map_rounded),
  'Builder Floor': ('Builder Floor', Icons.layers_rounded),
  '1RK/Studio Apartment': ('Studio', Icons.meeting_room_rounded),
};

const _kConstructionStatus = [
  ('Ready to Move', Icons.check_circle_outline_rounded),
  ('New Launch', Icons.auto_awesome_rounded),
  ('Under Construction', Icons.construction_rounded),
];

const _kBhkOptions = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '4+ BHK'];

const _kResidentialTypes = {
  'Apartments',
  'Villa',
  'Builder Floor',
  'Studio',
  'Independent House',
};

/// Whether the currently selected property types call for residential-only
/// filters (bedrooms, construction status, amenities). Plot/Land has none
/// of those attributes, so they're hidden when it's the only type picked.
bool _showsResidentialFilters(List<String> selectedTypes) {
  if (selectedTypes.isEmpty) return true;
  return selectedTypes.any(_kResidentialTypes.contains);
}

class LocationSearchScreen extends ConsumerStatefulWidget {
  /// False when embedded as a persistent bottom-nav tab (Explore) — there's
  /// nothing to pop back to from a tab, so the close button is hidden.
  final bool showCloseButton;

  const LocationSearchScreen({super.key, this.showCloseButton = true});

  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  String _intentTab = 'Buy';
  final _locationCtrl = TextEditingController();
  final _locationFocus = FocusNode();
  bool _locationChosen = false;
  String _radius = '3 km';
  bool _advancedExpanded = false;
  bool _locatingGps = false;

  Timer? _debounce;
  List<PlacePrediction> _suggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _locationFocus.addListener(() {
      debugPrint(
        '[LocationSearch] focus=${_locationFocus.hasFocus} at ${DateTime.now()}',
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationCtrl.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      return;
    }
    setState(() => _loadingSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref
          .read(googleGeocodingServiceProvider)
          .autocomplete(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  void _pickLocation(String label) {
    _debounce?.cancel();
    setState(() {
      _locationCtrl.text = label;
      _locationChosen = true;
      _suggestions = [];
      _loadingSuggestions = false;
    });
  }

  // NOTE: this field only feeds the local search query (city/locality text
  // used to filter listings on this screen) — it must never touch the
  // app-wide locationProvider, otherwise picking an address here would
  // silently become the Home screen's current location too.
  void _pickSuggestion(PlacePrediction suggestion) {
    _pickLocation(suggestion.description);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locatingGps = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location services are disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final label = await ref
          .read(googleGeocodingServiceProvider)
          .reverseGeocode(lat: pos.latitude, lng: pos.longitude);
      if (!mounted) return;
      if (label != null && label.trim().isNotEmpty) {
        _pickLocation(label);
      }
    } catch (_) {
      // Keep the field as-is; the GPS icon just won't fill anything in.
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  void _clearLocation() {
    _debounce?.cancel();
    setState(() {
      _locationCtrl.clear();
      _locationChosen = false;
      _suggestions = [];
      _loadingSuggestions = false;
    });
  }

  void _search() {
    final notifier = ref.read(propertyFilterProvider.notifier);
    final intent = _intentTab == 'Rent/PG'
        ? 'Rent'
        : _intentTab == 'Commercial'
        ? 'Commercial'
        : 'Buy';
    notifier.updateIntent(intent);
    notifier.updateCity(_locationCtrl.text.trim());

    context.push(
      '/name-search-results',
      extra: PropertyNameSearchArgs(
        query: _locationCtrl.text.trim(),
        mode: intent == 'Rent' ? 'rent' : 'buy',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(propertyFilterProvider);
    final notifier = ref.read(propertyFilterProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchField(),
                    ),
                  ),
                  if (!_locationChosen &&
                      (_locationCtrl.text.trim().isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: _buildSuggestions(),
                    )
                  else if (!_locationChosen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: _buildPopularCities(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: _buildFiltersPanel(filters, notifier),
                    ),
                ],
              ),
            ),
          ),
          if (_locationChosen) _buildBottomBar(notifier),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _orange,
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.paddingOf(context).top + 8,
        14,
        34,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  for (final tab in const ['Buy', 'Rent/PG', 'Commercial'])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _intentTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _intentTab == tab
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tab,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _intentTab == tab ? _orange : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.showCloseButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _locationCtrl,
              focusNode: _locationFocus,
              onTap: () =>
                  debugPrint('[LocationSearch] onTap at ${DateTime.now()}'),
              onChanged: (v) {
                if (_locationChosen) setState(() => _locationChosen = false);
                _onQueryChanged(v);
              },
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _pickLocation(v.trim());
              },
              style: const TextStyle(
                fontSize: 13,
                color: _navy,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Try - ATS Pristine Sector 150 Noida',
                hintStyle: TextStyle(
                  color: _grey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _locatingGps ? null : _useCurrentLocation,
            child: SizedBox(
              width: 36,
              height: 40,
              child: _locatingGps
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _orange,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: _orange,
                      size: 19,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _loadingSuggestions
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _orange,
                  ),
                ),
              ),
            )
          : _suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No matching places found',
                style: TextStyle(
                  color: _grey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF2F4F7)),
                  InkWell(
                    onTap: () => _pickSuggestion(_suggestions[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: _orange,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _suggestions[i].description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildPopularCities() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular cities in India',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in _kPopularCities)
                GestureDetector(
                  onTap: () => _pickLocation(city),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: _grey, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          city,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(
    PropertyFilterState filters,
    PropertyFilterNotifier notifier,
  ) {
    final showResidential = _showsResidentialFilters(
      filters.selectedPropertyTypes,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _orangeTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.near_me_rounded, color: _orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationCtrl.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearLocation,
                child: const Icon(Icons.close_rounded, color: _grey, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Show Properties within',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in const ['1 km', '3 km', '5 km', '10 km'])
                    GestureDetector(
                      onTap: () => setState(() => _radius = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _radius == r ? _orangeTint : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _radius == r ? _orange : _border,
                          ),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: _radius == r ? _orange : _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              BudgetSection(
                minBudget: filters.minBudget,
                maxBudget: filters.maxBudget,
                onBudgetChanged: notifier.updateBudget,
              ),
              const SizedBox(height: 16),
              const Text(
                'Property types',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _kPropertyTypeMap.entries)
                    _IconGridItem(
                      label: entry.key,
                      icon: entry.value.$2,
                      selected: filters.selectedPropertyTypes.contains(
                        entry.value.$1,
                      ),
                      onTap: () => notifier.togglePropertyType(entry.value.$1),
                    ),
                ],
              ),
              if (showResidential) ...[
                const SizedBox(height: 16),
                BhkSection(
                  selectedBhk: filters.selectedBhk
                      .where(_kBhkOptions.contains)
                      .toList(),
                  onBhkToggled: notifier.toggleBhk,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Construction status',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _kConstructionStatus)
                      _IconGridItem(
                        label: entry.$1,
                        icon: entry.$2,
                        selected: filters.selectedConstructionStatus.contains(
                          entry.$1,
                        ),
                        onTap: () =>
                            notifier.toggleConstructionStatus(entry.$1),
                      ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Bedrooms & construction status don\'t apply to plots/land.',
                    style: TextStyle(
                      color: _grey,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _advancedExpanded = !_advancedExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              showResidential
                                  ? 'Posted by, Area & Amenities'
                                  : 'Posted by & Area',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _advancedExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_advancedExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListedBySection(
                        selectedListedBy: filters.selectedListedBy,
                        selectedConstructionStatus:
                            filters.selectedConstructionStatus,
                        onListedByToggled: notifier.toggleListedBy,
                        onConstructionStatusToggled:
                            notifier.toggleConstructionStatus,
                      ),
                      const SizedBox(height: 18),
                      AreaSection(
                        minArea: filters.minArea,
                        maxArea: filters.maxArea,
                        onAreaChanged: notifier.updateArea,
                      ),
                      if (showResidential) ...[
                        const SizedBox(height: 18),
                        AmenitiesSection(
                          selectedAmenities: filters.selectedAmenities,
                          onAmenityToggled: notifier.toggleAmenity,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(PropertyFilterNotifier notifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                notifier.clearFilters();
                _clearLocation();
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: Material(
                  color: _orange,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _search,
                    child: const Center(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
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
}

class _IconGridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconGridItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _orangeTint : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? _orange : _border),
              ),
              child: Icon(icon, color: selected ? _orange : _grey, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: selected ? _orange : _navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
