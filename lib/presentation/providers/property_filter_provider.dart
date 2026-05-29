import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/property_filter_model.dart';

final propertyFilterProvider = StateNotifierProvider<PropertyFilterNotifier, PropertyFilterState>((ref) {
  return PropertyFilterNotifier();
});

class PropertyFilterNotifier extends StateNotifier<PropertyFilterState> {
  static const _prefKey = 'property_filters_state';

  PropertyFilterNotifier() : super(PropertyFilterState.initial()) {
    _restoreFilters();
  }

  Future<void> _restoreFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        state = PropertyFilterState.fromJson(jsonStr);
      }
    } catch (_) {}
  }

  Future<void> _saveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, state.toJson());
    } catch (_) {}
  }

  void toggleBhk(String value) {
    final list = [...state.selectedBhk];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedBhk: list);
    _saveFilters();
  }

  void togglePropertyType(String value) {
    final list = [...state.selectedPropertyTypes];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedPropertyTypes: list);
    _saveFilters();
  }

  void toggleDeveloper(String value) {
    final list = [...state.selectedDevelopers];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedDevelopers: list);
    _saveFilters();
  }

  void toggleConstructionStatus(String value) {
    final list = [...state.selectedConstructionStatus];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedConstructionStatus: list);
    _saveFilters();
  }

  void toggleListedBy(String value) {
    final list = [...state.selectedListedBy];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedListedBy: list);
    _saveFilters();
  }

  void toggleLocality(String value) {
    final list = [...state.selectedLocalities];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    state = state.copyWith(selectedLocalities: list);
    _saveFilters();
  }

  void addLocality(String value) {
    if (!state.selectedLocalities.contains(value)) {
      state = state.copyWith(selectedLocalities: [...state.selectedLocalities, value]);
      _saveFilters();
    }
  }

  void removeLocality(String value) {
    state = state.copyWith(
      selectedLocalities: state.selectedLocalities.where((l) => l != value).toList(),
    );
    _saveFilters();
  }

  void updateBudget(double min, double max) {
    state = state.copyWith(minBudget: min, maxBudget: max);
    _saveFilters();
  }

  void updateIntent(String value) {
    state = state.copyWith(selectedIntent: value);
    _saveFilters();
  }

  void updateCity(String value) {
    state = state.copyWith(selectedCity: value);
    _saveFilters();
  }

  void clearFilters() {
    state = PropertyFilterState.initial();
    _saveFilters();
  }

  int getActiveFilterCount() {
    int count = 0;
    if (state.selectedLocalities.isNotEmpty) count += 1;
    if (state.selectedBhk.isNotEmpty) count += 1;
    if (state.selectedPropertyTypes.isNotEmpty) count += 1;
    if (state.selectedDevelopers.isNotEmpty) count += 1;
    if (state.selectedListedBy.isNotEmpty) count += 1;
    if (state.selectedConstructionStatus.isNotEmpty) count += 1;
    if (state.minBudget > 0.0 || state.maxBudget < 20.0) count += 1;
    return count;
  }
}
