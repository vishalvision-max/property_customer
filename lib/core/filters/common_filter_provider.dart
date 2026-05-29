import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'common_filter.dart';

part 'common_filter_provider.g.dart';

@riverpod
class CommonFilterNotifier extends _$CommonFilterNotifier {
  @override
  CommonFilter build() {
    return CommonFilter.initial();
  }

  /// Update the search text filter
  void updateSearchText(String text) {
    state = state.copyWith(searchText: text);
  }

  /// Update the property type filter (e.g. 'Studio', '1BHK', '2BHK', 'Condo', 'House', 'Any')
  void updatePropertyType(String type) {
    state = state.copyWith(propertyType: type);
  }

  /// Update the listing type filter (e.g. 'rent', 'buy', 'Any')
  void updateListingType(String type) {
    state = state.copyWith(listingType: type);
  }

  /// Update the city filter
  void updateCity(String city) {
    state = state.copyWith(city: city);
  }

  /// Update the state filter
  void updateState(String stateName) {
    state = state.copyWith(state: stateName);
  }

  /// Update the price range filter
  void updatePriceRange(RangeValues? range) {
    if (range == null) {
      state = state.copyWithNull(priceRange: true);
    } else {
      state = state.copyWith(priceRange: range);
    }
  }

  /// Update the area range filter
  void updateAreaRange(RangeValues? range) {
    if (range == null) {
      state = state.copyWithNull(areaRange: true);
    } else {
      state = state.copyWith(areaRange: range);
    }
  }

  /// Update the bedrooms count filter
  void updateBedrooms(int? count) {
    if (count == null) {
      state = state.copyWithNull(bedrooms: true);
    } else {
      state = state.copyWith(bedrooms: count);
    }
  }

  /// Update the bathrooms count filter
  void updateBathrooms(int? count) {
    if (count == null) {
      state = state.copyWithNull(bathrooms: true);
    } else {
      state = state.copyWith(bathrooms: count);
    }
  }

  /// Update the active list of amenities
  void updateAmenities(List<String> amenities) {
    state = state.copyWith(amenities: amenities);
  }

  /// Update sorting criteria
  void updateSort(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  /// Reset all filters back to initial state
  void resetFilters() {
    state = CommonFilter.initial();
  }

  /// Force-apply current filters (triggering state updates to all consumers)
  void applyFilters() {
    state = state.copyWith();
  }
}
