import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/search_history_item.dart';
import '../../data/services/search_history_service.dart';

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

final searchHistoryProvider = StateNotifierProvider<
    SearchHistoryNotifier,
    AsyncValue<List<SearchHistoryItem>>
>((ref) {
  final service = ref.watch(searchHistoryServiceProvider);
  return SearchHistoryNotifier(service);
});

class SearchHistoryNotifier extends StateNotifier<AsyncValue<List<SearchHistoryItem>>> {
  final SearchHistoryService _service;

  SearchHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = const AsyncValue.loading();
      final items = await _service.getRecentSearches();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveSearch(SearchHistoryItem item) async {
    try {
      await _service.saveSearch(item);
      final items = await _service.getRecentSearches();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeSearch(String id) async {
    try {
      await _service.removeSearch(id);
      final items = await _service.getRecentSearches();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearHistory() async {
    try {
      await _service.clearAllSearches();
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
