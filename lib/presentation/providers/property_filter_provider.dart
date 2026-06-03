import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/property_filter_model.dart';

final propertyFilterProvider = StateNotifierProvider<PropertyFilterNotifier, PropertyFilterState>((ref) {
  return PropertyFilterNotifier();
});

class PropertyFilterNotifier extends StateNotifier<PropertyFilterState> {
  static const _prefKey = 'property_filters_state';

  PropertyFilterNotifier() : super(PropertyFilterState.initial());

  // SharedPreferences persistence removed as per user request to start fresh.
  void _saveFilters() {}

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

  void toggleFurnishing(String value) {
    final list = [...state.selectedFurnishing];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedFurnishing: list);
    _saveFilters();
  }

  void toggleVerifiedOnly(bool value) {
    state = state.copyWith(verifiedOnly: value);
    _saveFilters();
  }

  void toggleImagesOnly(bool value) {
    state = state.copyWith(imagesOnly: value);
    _saveFilters();
  }

  void updateArea(double min, double max) {
    state = state.copyWith(minArea: min, maxArea: max);
    _saveFilters();
  }

  void toggleLeaseType(String value) {
    final list = [...state.selectedLeaseTypes];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedLeaseTypes: list);
    _saveFilters();
  }

  void toggleBathroom(String value) {
    final list = [...state.selectedBathrooms];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedBathrooms: list);
    _saveFilters();
  }

  void toggleAge(String value) {
    final list = [...state.selectedAge];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedAge: list);
    _saveFilters();
  }

  void toggleAdded(String value) {
    final list = [...state.selectedAdded];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedAdded: list);
    _saveFilters();
  }

  void toggleAvailable(String value) {
    final list = [...state.selectedAvailable];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedAvailable: list);
    _saveFilters();
  }

  void togglePowerBackup(String value) {
    final list = [...state.selectedPowerBackup];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedPowerBackup: list);
    _saveFilters();
  }

  void toggleAmenity(String value) {
    final list = [...state.selectedAmenities];
    if (list.contains(value)) list.remove(value);
    else list.add(value);
    state = state.copyWith(selectedAmenities: list);
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
    if (state.selectedFurnishing.isNotEmpty) count += 1;
    if (state.verifiedOnly) count += 1;
    if (state.imagesOnly) count += 1;
    if (state.minArea > 0.0 || state.maxArea < 5000.0) count += 1;
    if (state.selectedLeaseTypes.isNotEmpty) count += 1;
    if (state.selectedBathrooms.isNotEmpty) count += 1;
    if (state.selectedAge.isNotEmpty) count += 1;
    if (state.selectedAdded.isNotEmpty) count += 1;
    if (state.selectedAvailable.isNotEmpty) count += 1;
    if (state.selectedPowerBackup.isNotEmpty) count += 1;
    if (state.selectedAmenities.isNotEmpty) count += 1;
    return count;
  }
}
