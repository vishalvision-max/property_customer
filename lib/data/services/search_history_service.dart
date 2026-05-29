import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history_item.dart';

class SearchHistoryService {
  static const String _kSearchHistoryKey = 'search_history';

  Future<void> saveSearch(SearchHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRecentSearches();

    // Rules:
    // 1. New searches appear at top.
    // 2. Duplicate searches should not be added.
    // 3. If same search exists:
    //    remove old entry
    //    insert at first position.
    // 4. Maximum 10 recent searches.
    // 5. Automatically remove oldest items when limit exceeds.

    // Remove if duplicate text exists (exact match)
    list.removeWhere((x) => x.searchText.trim() == item.searchText.trim());
    
    // Also handle if duplicate ID exists, just in case
    list.removeWhere((x) => x.id == item.id);

    // Insert at first position
    list.insert(0, item);

    // Maximum 10 recent searches
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }

    final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kSearchHistoryKey, jsonList);
  }

  Future<List<SearchHistoryItem>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_kSearchHistoryKey);
    if (jsonList == null) return [];

    final List<SearchHistoryItem> items = [];
    for (final raw in jsonList) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        items.add(SearchHistoryItem.fromJson(decoded));
      } catch (_) {
        // Skip malformed entries
      }
    }
    return items;
  }

  Future<void> removeSearch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRecentSearches();
    list.removeWhere((x) => x.id == id);

    final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kSearchHistoryKey, jsonList);
  }

  Future<void> clearAllSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchHistoryKey);
  }
}
