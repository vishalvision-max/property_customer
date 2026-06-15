import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../data/models/search_history_item.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/location_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/recent_searches_section.dart';
import '../property/property_name_search_args.dart';
import 'name_search_args.dart';

class NameSearchScreen extends ConsumerStatefulWidget {
  const NameSearchScreen({super.key});

  @override
  ConsumerState<NameSearchScreen> createState() => _NameSearchScreenState();
}

class _NameSearchScreenState extends ConsumerState<NameSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final TextEditingController _minBudgetCtrl = TextEditingController();
  final TextEditingController _maxBudgetCtrl = TextEditingController();
  final TextEditingController _minAreaCtrl = TextEditingController();
  final TextEditingController _maxAreaCtrl = TextEditingController();

  Timer? _debounce;
  Timer? _debounceCount;
  Future<List<Property>>? _future;
  int? _remoteCount;
  String _mode = 'rent';
  bool _showAdvanceFilters = false;
  bool _isLocationSelected = false;

  final List<String> _selectedPropTypes = [];
  final List<String> _selectedBedrooms = [];
  String? _selectedConstStatus;
  final List<String> _selectedPostedBy = [];
  int _minBedroomsCount = 0;
  final List<String> _selectedAmenities = [];

  final _propTypes = [
    'Flat/Apartment',
    'House/Villa',
    'Service Apartment',
    'Farm House',
    'Plot/Land',
    'Builder Floor',
    '1RK/Studio Apartment',
  ];
  final _bedroomsList = ['1', '2', '3', '4', '4+'];
  final _constStatusList = [

    'New Launch',
    'Under Construction',
    'Ready to Move',
  ];
  final _postedByList = ['Owner', 'Builder', 'Dealer'];
  final _amenitiesList = [
    'Parking',
    'Gym',
    'Pool',
    'Security',
    'Club House',
    'Power Backup',
    'Lift',
    'Park',
  ];

  @override
  void initState() {
    super.initState();
    _minBudgetCtrl.addListener(_triggerCountUpdate);
    _maxBudgetCtrl.addListener(_triggerCountUpdate);
    _minAreaCtrl.addListener(_triggerCountUpdate);
    _maxAreaCtrl.addListener(_triggerCountUpdate);
    _ctrl.addListener(_triggerCountUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCountUpdate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is NameSearchArgs) {
      _mode = extra.mode;
    }
  }

  void _triggerCountUpdate() {
    _debounceCount?.cancel();
    _debounceCount = Timer(const Duration(milliseconds: 300), () async {
      try {
        final ps = ref.read(propertyServiceProvider);
        
        final c = await ps.fetchPropertyCount(
          type: _mode == 'buy' ? 'sale' : (_mode == 'rent' ? 'rent' : _mode),
          city: _ctrl.text.isNotEmpty ? _ctrl.text : null,
          bhk: _selectedBedrooms,
          propertyKinds: _selectedPropTypes,
          minArea: double.tryParse(_minAreaCtrl.text),
          maxArea: double.tryParse(_maxAreaCtrl.text),
          minPrice: double.tryParse(_minBudgetCtrl.text),
          maxPrice: double.tryParse(_maxBudgetCtrl.text),
          amenities: _selectedAmenities,
        );
        if (!mounted) return;
        setState(() {
          _remoteCount = c;
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _debounceCount?.cancel();
    _ctrl.dispose();
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _ctrl.clear();
      _minBudgetCtrl.clear();
      _maxBudgetCtrl.clear();
      _minAreaCtrl.clear();
      _maxAreaCtrl.clear();
      _selectedPropTypes.clear();
      _selectedBedrooms.clear();
      _selectedConstStatus = null;
      _selectedPostedBy.clear();
      _minBedroomsCount = 0;
      _selectedAmenities.clear();
      _future = null;
      _showAdvanceFilters = false;
      _isLocationSelected = false;
      _remoteCount = null;
    });
    _triggerCountUpdate();
  }

  void _run(String q) {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _future = null);
      return;
    }
    setState(() {
      _future = ref
          .read(propertyNotifierProvider.notifier)
          .searchByName(mode: _mode, query: query);
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(v));
  }

  void _executeSearch(String queryText) {
    final q = queryText.trim();
    
    if (q.isNotEmpty) {
      final item = SearchHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        searchText: q,
        createdAt: DateTime.now(),
      );
      ref.read(searchHistoryProvider.notifier).saveSearch(item);
    }

    context.push(
      '/name-search-results',
      extra: PropertyNameSearchArgs(query: q, mode: _mode),
    );
  }

  void _onRecentSearchTap(SearchHistoryItem item) {
    setState(() {
      _ctrl.text = item.searchText;
      _run(item.searchText);
    });
    _executeSearch(item.searchText);
  }

  void _submit() {
    final q = _ctrl.text.trim();
    _executeSearch(q);
  }

  Widget _buildTab(String label, String value) {
    final isSelected = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = value;
          });
          _triggerCountUpdate();
          if (_ctrl.text.isNotEmpty) {
            _run(_ctrl.text);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(searchHistoryProvider);
              return historyAsync.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      RecentSearchesSection(
                        items: items,
                        onRecentSearchTap: _onRecentSearchTap,
                        onClearAll: () {
                          ref
                              .read(searchHistoryProvider.notifier)
                              .clearHistory();
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
          if (_isLocationSelected) ...[
            _buildSectionTitle('Budget'),
            Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minBudgetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Min (₹)',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxBudgetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Max (₹)',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildSectionTitle('Property Types'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _propTypes.map((type) {
              final isSelected = _selectedPropTypes.contains(type);
              return ChoiceChip(
                label: Text(type, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedPropTypes.add(type);
                    } else {
                      _selectedPropTypes.remove(type);
                    }
                  });
                  _triggerCountUpdate();
                },
              );
            }).toList(),
          ),
          _buildSectionTitle('No. of Bedrooms'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _bedroomsList.map((type) {
              final isSelected = _selectedBedrooms.contains(type);
              return ChoiceChip(
                label: Text(type, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedBedrooms.add(type);
                    } else {
                      _selectedBedrooms.remove(type);
                    }
                  });
                  _triggerCountUpdate();
                },
              );
            }).toList(),
          ),
          _buildSectionTitle('Construction Status'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _constStatusList.map((type) {
              final isSelected = _selectedConstStatus == type;
              return ChoiceChip(
                label: Text(type, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    _selectedConstStatus = val ? type : null;
                  });
                  _triggerCountUpdate();
                },
              );
            }).toList(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Divider(thickness: 1),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _showAdvanceFilters = !_showAdvanceFilters;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Advance Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showAdvanceFilters
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvanceFilters) ...[
            _buildSectionTitle('Posted By'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _postedByList.map((type) {
                final isSelected = _selectedPostedBy.contains(type);
                return ChoiceChip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedPostedBy.add(type);
                      } else {
                        _selectedPostedBy.remove(type);
                      }
                    });
                    _triggerCountUpdate();
                  },
                );
              }).toList(),
            ),
            _buildSectionTitle('Area (sq.ft)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAreaCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Min Area',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxAreaCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Max Area',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _buildSectionTitle('Minimum no. of bedrooms'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bedrooms', style: TextStyle(fontSize: 14)),
                Row(
                  children: [
                    if (_minBedroomsCount > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _minBedroomsCount--);
                          _triggerCountUpdate();
                        },
                      ),
                    Text(
                      '$_minBedroomsCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _minBedroomsCount++);
                        _triggerCountUpdate();
                      },
                    ),
                  ],
                ),
              ],
            ),
            _buildSectionTitle('Amenities'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _amenitiesList.map((type) {
                final isSelected = _selectedAmenities.contains(type);
                return ChoiceChip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedAmenities.add(type);
                      } else {
                        _selectedAmenities.remove(type);
                      }
                    });
                    _triggerCountUpdate();
                  },
                );
              }).toList(),
            ),
          ],
          ], // Closes if (_isLocationSelected) ...[
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Property>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const <Property>[];
        if (items.isEmpty) {
          return const Center(child: Text('No matches'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = items[i];
            return PropertyCard(
              property: p,
              onTap: () => context.push('/property/${p.id}'),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = _future;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        // title: const Text('Search Properties', style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildTab('Buy', 'buy'),
                _buildTab('Rent', 'rent'),
                _buildTab('PG', 'pg'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search location or property name…',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.my_location, size: 20),
                  onPressed: () async {
                    final locNotifier = ref.read(locationProvider.notifier);
                    String locLabel = ref.read(locationProvider).currentLabel;
                    
                    if (locLabel == 'Set location' || locLabel == 'Unknown Location' || locLabel.isEmpty) {
                      await locNotifier.fetchCurrent();
                      locLabel = ref.read(locationProvider).currentLabel;
                    }

                    if (locLabel == 'Set location' || locLabel == 'Unknown Location') {
                      locLabel = '';
                    } else if (locLabel.contains(',')) {
                      locLabel = locLabel.split(',').first.trim();
                    }

                    if (!mounted) return;
                    setState(() {
                      _isLocationSelected = true;
                      _ctrl.text = locLabel;
                    });
                  },
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    _ctrl.clear();
                    _run('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(child: f == null ? _buildFilterUI() : _buildSearchResults()),
          if (_isLocationSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _remoteCount == null ? 'Loading...' : 'See All $_remoteCount Properties',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ) else const SizedBox.shrink(),
        ],
      ),
    );
  }
}
