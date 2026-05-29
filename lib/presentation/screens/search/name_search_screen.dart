import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/property.dart';
import '../../../data/models/search_history_item.dart';
import '../../../providers/property_provider.dart';
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
  Timer? _debounce;
  Future<List<Property>>? _future;
  String _mode = 'rent';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is NameSearchArgs) {
      _mode = extra.mode;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
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
    if (q.isEmpty) return;

    // Save to history
    final item = SearchHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      searchText: q,
      createdAt: DateTime.now(),
    );
    ref.read(searchHistoryProvider.notifier).saveSearch(item);

    // Push to name search results screen
    context.push(
      '/name-search-results',
      extra: PropertyNameSearchArgs(query: q, mode: _mode),
    );
  }

  void _onRecentSearchTap(SearchHistoryItem item) {
    setState(() {
      _ctrl.text = item.searchText;
      // Triggers dynamic search listing as well, in case we return
      _run(item.searchText);
    });
    _executeSearch(item.searchText);
  }

  void _submit() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _executeSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final f = _future;
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Search by name')),
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
              decoration: InputDecoration(
                hintText: 'Type property name…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    _ctrl.clear();
                    _run('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: f == null
                ? Consumer(
                    builder: (context, ref, child) {
                      final historyAsync = ref.watch(searchHistoryProvider);
                      return historyAsync.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return const Center(
                              child: Text(
                                'Start typing to search',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(height: 60),
                                const Center(
                                  child: Text(
                                    'Start typing to search',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, _) => const Center(
                          child: Text(
                            'Start typing to search',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : FutureBuilder<List<Property>>(
                    future: f,
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final p = items[i];
                          return PropertyCard(
                            property: p,
                            onTap: () => context.push('/property/${p.id}'),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        icon: const Icon(Icons.search_rounded),
        label: const Text('Search'),
      ),
    );
  }
}
