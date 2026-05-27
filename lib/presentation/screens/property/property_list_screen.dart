import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../data/services/property_service.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../../widgets/shimmer_list.dart';
import '../search/search_args.dart';
import 'property_list_args.dart';
import 'property_name_search_args.dart';

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({super.key});

  @override
  ConsumerState<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  late Future<List<Property>> _future;
  String _title = 'Properties';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is SearchArgs) {
      _title = _titleForSearchArgs(extra);
      if (extra.fromTab) {
        // Quick-action tab: use nearby/fetchAll + client-side filter.
        // The backend /properties?type= endpoint returns 0 results.
        final loc = ref.read(locationProvider);
        _future = ref
            .read(propertyProvider.notifier)
            .fetchForType(
              mode: extra.mode,
              propertyType: extra.propertyType == 'Any'
                  ? null
                  : extra.propertyType,
              lat: loc.lat,
              lng: loc.lng,
            );
      } else {
        // User-driven filter search — use the full search pipeline.
        _future = ref
            .read(propertyProvider.notifier)
            .search(
              mode: extra.mode,
              budgetRange: BudgetRange(extra.budget.start, extra.budget.end),
              propertyType: extra.propertyType,
              amenities: extra.amenities,
              locationQuery: extra.locationQuery,
              sortBy: extra.sortBy,
            );
      }
    } else if (extra is PropertyNameSearchArgs) {
      _title = 'Search: ${extra.query}';
      _future = ref
          .read(propertyProvider.notifier)
          .searchByName(mode: extra.mode, query: extra.query);
    } else if (extra is PropertyListArgs) {
      _title = extra.title;
      _future = Future.value(extra.items);
    } else {
      _future = Future.value(ref.read(propertyProvider).all);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: FutureBuilder<List<Property>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const ShimmerList();
          }
          final items = snap.data ?? const <Property>[];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No results',
              message:
                  'Try adjusting filters or searching a different location.',
              asset: 'assets/illustrations/empty_search.svg',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length + 1,
            separatorBuilder: (context, index) => SizedBox(height: index == 0 ? 0 : 8),
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
        },
      ),
    );
  }
}
